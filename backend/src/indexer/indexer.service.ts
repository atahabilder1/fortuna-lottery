import { Injectable, OnModuleInit, Logger } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { createPublicClient, http, parseAbiItem } from 'viem';
import { baseSepolia } from 'viem/chains';

const FORTUNA_LOTTERY_ADDRESS = (process.env.CONTRACT_ADDRESS ||
  '0x0000000000000000000000000000000000000000') as `0x${string}`;

@Injectable()
export class IndexerService implements OnModuleInit {
  private readonly logger = new Logger(IndexerService.name);
  private client: ReturnType<typeof createPublicClient>;

  constructor(private prisma: PrismaService) {
    this.client = createPublicClient({
      chain: baseSepolia,
      transport: http(process.env.RPC_URL || baseSepolia.rpcUrls.default.http[0]),
    });
  }

  async onModuleInit() {
    this.logger.log('Starting event indexer...');
    await this.indexHistoricalEvents();
    this.startWatchingEvents();
  }

  private async indexHistoricalEvents() {
    this.logger.log('Indexing historical events...');
    try {
      const latestBlock = await this.client.getBlockNumber();
      const fromBlock = BigInt(process.env.START_BLOCK || 0);

      await this.indexLotteryCreated(fromBlock, latestBlock);
      await this.indexParticipantRegistered(fromBlock, latestBlock);
      await this.indexTokensPlaced(fromBlock, latestBlock);
      await this.indexWinnerSelected(fromBlock, latestBlock);

      this.logger.log('Historical events indexed successfully');
    } catch (error) {
      this.logger.error('Error indexing historical events:', error);
    }
  }

  private async indexLotteryCreated(fromBlock: bigint, toBlock: bigint) {
    const logs = await this.client.getLogs({
      address: FORTUNA_LOTTERY_ADDRESS,
      event: parseAbiItem(
        'event LotteryCreated(uint256 indexed lotteryId, uint256 itemCount, uint256 tokensPerParticipant, uint256 startTime, uint256 endTime)'
      ),
      fromBlock,
      toBlock,
    });

    for (const log of logs) {
      const { lotteryId, itemCount, tokensPerParticipant, startTime, endTime } = log.args;

      await this.prisma.lottery.upsert({
        where: { contractLotteryId: Number(lotteryId) },
        update: {},
        create: {
          contractLotteryId: Number(lotteryId),
          name: `Lottery #${lotteryId}`,
          tokensPerParticipant: Number(tokensPerParticipant),
          startTime: new Date(Number(startTime) * 1000),
          endTime: new Date(Number(endTime) * 1000),
          itemCount: Number(itemCount),
          isActive: true,
        },
      });
    }

    this.logger.log(`Indexed ${logs.length} LotteryCreated events`);
  }

  private async indexParticipantRegistered(fromBlock: bigint, toBlock: bigint) {
    const logs = await this.client.getLogs({
      address: FORTUNA_LOTTERY_ADDRESS,
      event: parseAbiItem(
        'event ParticipantRegistered(uint256 indexed lotteryId, address indexed participant, uint256 tokensReceived)'
      ),
      fromBlock,
      toBlock,
    });

    for (const log of logs) {
      const { lotteryId, participant, tokensReceived } = log.args;

      const lottery = await this.prisma.lottery.findUnique({
        where: { contractLotteryId: Number(lotteryId) },
      });

      if (lottery) {
        await this.prisma.participant.upsert({
          where: {
            lotteryId_address: {
              lotteryId: lottery.id,
              address: participant,
            },
          },
          update: {},
          create: {
            lotteryId: lottery.id,
            address: participant,
            totalTokens: Number(tokensReceived),
            tokensUsed: 0,
            registered: true,
          },
        });
      }
    }

    this.logger.log(`Indexed ${logs.length} ParticipantRegistered events`);
  }

  private async indexTokensPlaced(fromBlock: bigint, toBlock: bigint) {
    const logs = await this.client.getLogs({
      address: FORTUNA_LOTTERY_ADDRESS,
      event: parseAbiItem(
        'event TokensPlaced(uint256 indexed lotteryId, address indexed participant, uint256 indexed itemId, uint256 tokens)'
      ),
      fromBlock,
      toBlock,
    });

    for (const log of logs) {
      const { lotteryId, participant, itemId, tokens } = log.args;

      const lottery = await this.prisma.lottery.findUnique({
        where: { contractLotteryId: Number(lotteryId) },
      });

      if (lottery) {
        const lotteryItem = await this.prisma.lotteryItem.findFirst({
          where: {
            lotteryId: lottery.id,
            contractItemId: Number(itemId),
          },
        });

        if (!lotteryItem) {
          await this.prisma.lotteryItem.create({
            data: {
              lotteryId: lottery.id,
              contractItemId: Number(itemId),
              name: `Item #${itemId}`,
              description: 'Item description',
              totalTokens: Number(tokens),
            },
          });
        } else {
          await this.prisma.lotteryItem.update({
            where: { id: lotteryItem.id },
            data: {
              totalTokens: { increment: Number(tokens) },
            },
          });
        }

        await this.prisma.participant.updateMany({
          where: {
            lotteryId: lottery.id,
            address: participant,
          },
          data: {
            tokensUsed: { increment: Number(tokens) },
          },
        });
      }
    }

    this.logger.log(`Indexed ${logs.length} TokensPlaced events`);
  }

  private async indexWinnerSelected(fromBlock: bigint, toBlock: bigint) {
    const logs = await this.client.getLogs({
      address: FORTUNA_LOTTERY_ADDRESS,
      event: parseAbiItem(
        'event WinnerSelected(uint256 indexed lotteryId, uint256 indexed itemId, address indexed winner, uint256 requestId)'
      ),
      fromBlock,
      toBlock,
    });

    for (const log of logs) {
      const { lotteryId, itemId, winner } = log.args;

      const lottery = await this.prisma.lottery.findUnique({
        where: { contractLotteryId: Number(lotteryId) },
      });

      if (lottery) {
        await this.prisma.lotteryItem.updateMany({
          where: {
            lotteryId: lottery.id,
            contractItemId: Number(itemId),
          },
          data: {
            winner: winner,
            winnerSelected: true,
          },
        });
      }
    }

    this.logger.log(`Indexed ${logs.length} WinnerSelected events`);
  }

  private startWatchingEvents() {
    this.logger.log('Starting to watch for new events...');

    this.client.watchEvent({
      address: FORTUNA_LOTTERY_ADDRESS,
      event: parseAbiItem(
        'event LotteryCreated(uint256 indexed lotteryId, uint256 itemCount, uint256 tokensPerParticipant, uint256 startTime, uint256 endTime)'
      ),
      onLogs: async (logs) => {
        for (const log of logs) {
          const { lotteryId, itemCount, tokensPerParticipant, startTime, endTime } = log.args;
          await this.prisma.lottery.upsert({
            where: { contractLotteryId: Number(lotteryId) },
            update: {},
            create: {
              contractLotteryId: Number(lotteryId),
              name: `Lottery #${lotteryId}`,
              tokensPerParticipant: Number(tokensPerParticipant),
              startTime: new Date(Number(startTime) * 1000),
              endTime: new Date(Number(endTime) * 1000),
              itemCount: Number(itemCount),
              isActive: true,
            },
          });
          this.logger.log(`New lottery created: ${lotteryId}`);
        }
      },
    });

    this.client.watchEvent({
      address: FORTUNA_LOTTERY_ADDRESS,
      event: parseAbiItem(
        'event ParticipantRegistered(uint256 indexed lotteryId, address indexed participant, uint256 tokensReceived)'
      ),
      onLogs: async (logs) => {
        for (const log of logs) {
          const { lotteryId, participant, tokensReceived } = log.args;
          const lottery = await this.prisma.lottery.findUnique({
            where: { contractLotteryId: Number(lotteryId) },
          });
          if (lottery) {
            await this.prisma.participant.upsert({
              where: {
                lotteryId_address: {
                  lotteryId: lottery.id,
                  address: participant,
                },
              },
              update: {},
              create: {
                lotteryId: lottery.id,
                address: participant,
                totalTokens: Number(tokensReceived),
                tokensUsed: 0,
                registered: true,
              },
            });
            this.logger.log(`New participant registered: ${participant}`);
          }
        }
      },
    });
  }
}
