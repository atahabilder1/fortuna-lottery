import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class LotteryService {
  constructor(private prisma: PrismaService) {}

  async findAll() {
    const lotteries = await this.prisma.lottery.findMany({
      orderBy: { createdAt: 'desc' },
    });
    return {
      data: lotteries,
      message: 'Lotteries retrieved successfully',
    };
  }

  async findOne(id: number) {
    const lottery = await this.prisma.lottery.findUnique({
      where: { id },
      include: {
        items: true,
        participants: true,
      },
    });
    return {
      data: lottery,
      message: lottery ? 'Lottery retrieved successfully' : 'Lottery not found',
    };
  }

  async getItems(lotteryId: number) {
    const items = await this.prisma.lotteryItem.findMany({
      where: { lotteryId },
      orderBy: { contractItemId: 'asc' },
    });
    return {
      data: items,
      message: 'Lottery items retrieved successfully',
    };
  }

  async getParticipants(lotteryId: number) {
    const participants = await this.prisma.participant.findMany({
      where: { lotteryId },
      orderBy: { totalTokens: 'desc' },
    });
    return {
      data: participants,
      message: 'Participants retrieved successfully',
    };
  }
}
