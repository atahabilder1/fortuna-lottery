import { Module } from '@nestjs/common';
import { LotteryModule } from './lottery/lottery.module';
import { PrismaModule } from './prisma/prisma.module';
import { IndexerModule } from './indexer/indexer.module';

@Module({
  imports: [PrismaModule, LotteryModule, IndexerModule],
})
export class AppModule {}
