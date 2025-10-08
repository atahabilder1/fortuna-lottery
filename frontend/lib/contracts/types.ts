export interface LotteryInfo {
  name: string;
  tokensPerParticipant: bigint;
  startTime: bigint;
  endTime: bigint;
  itemCount: bigint;
  isActive: boolean;
}

export interface ItemInfo {
  name: string;
  description: string;
  totalTokens: bigint;
  winner: `0x${string}`;
  winnerSelected: boolean;
}

export interface ParticipantInfo {
  totalTokens: bigint;
  tokensUsed: bigint;
  registered: boolean;
}

export interface Lottery {
  lotteryId: number;
  name: string;
  tokensPerParticipant: number;
  startTime: number;
  endTime: number;
  itemCount: number;
  isActive: boolean;
}

export interface LotteryItem {
  itemId: number;
  name: string;
  description: string;
  totalTokens: number;
  winner?: string;
  winnerSelected: boolean;
}

export interface Participant {
  address: string;
  totalTokens: number;
  tokensUsed: number;
  registered: boolean;
}
