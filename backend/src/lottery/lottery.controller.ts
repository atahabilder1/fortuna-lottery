import { Controller, Get, Param } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse } from '@nestjs/swagger';
import { LotteryService } from './lottery.service';

@ApiTags('lottery')
@Controller('lottery')
export class LotteryController {
  constructor(private readonly lotteryService: LotteryService) {}

  @Get()
  @ApiOperation({ summary: 'Get all lotteries' })
  @ApiResponse({ status: 200, description: 'Returns all lotteries' })
  findAll() {
    return this.lotteryService.findAll();
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get lottery by ID' })
  @ApiResponse({ status: 200, description: 'Returns lottery details' })
  findOne(@Param('id') id: string) {
    return this.lotteryService.findOne(+id);
  }

  @Get(':id/items')
  @ApiOperation({ summary: 'Get lottery items' })
  @ApiResponse({ status: 200, description: 'Returns lottery items' })
  getItems(@Param('id') id: string) {
    return this.lotteryService.getItems(+id);
  }

  @Get(':id/participants')
  @ApiOperation({ summary: 'Get lottery participants' })
  @ApiResponse({ status: 200, description: 'Returns lottery participants' })
  getParticipants(@Param('id') id: string) {
    return this.lotteryService.getParticipants(+id);
  }
}
