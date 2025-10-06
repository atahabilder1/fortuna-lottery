import { Module } from '@nestjs/common';
import { LotteryModule } from './lottery/lottery.module';

@Module({
  imports: [LotteryModule],
})
export class AppModule {}
