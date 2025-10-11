import { Module } from '@nestjs/common';
import { LotteryModule } from './lottery/lottery.module';
import { PrismaModule } from './prisma/prisma.module';

@Module({
  imports: [PrismaModule, LotteryModule],
})
export class AppModule {}
