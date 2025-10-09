'use client';

import { useLotteryInfo } from '@/lib/contracts';
import { LotteryCard } from './LotteryCard';

interface LotteryItemProps {
  lotteryId: bigint;
}

function LotteryItem({ lotteryId }: LotteryItemProps) {
  const { data: lotteryInfo, isLoading, error } = useLotteryInfo(lotteryId);

  if (isLoading) {
    return (
      <div className="border border-gray-200 dark:border-gray-800 rounded-lg p-6 animate-pulse">
        <div className="h-6 bg-gray-200 dark:bg-gray-800 rounded mb-4"></div>
        <div className="h-4 bg-gray-200 dark:bg-gray-800 rounded mb-2"></div>
        <div className="h-4 bg-gray-200 dark:bg-gray-800 rounded"></div>
      </div>
    );
  }

  if (error || !lotteryInfo) {
    return null;
  }

  const [name, tokensPerParticipant, startTime, endTime, itemCount, isActive] = lotteryInfo;

  return (
    <LotteryCard
      lotteryId={Number(lotteryId)}
      name={name}
      tokensPerParticipant={Number(tokensPerParticipant)}
      startTime={Number(startTime)}
      endTime={Number(endTime)}
      itemCount={Number(itemCount)}
      isActive={isActive}
    />
  );
}

interface LotteryListProps {
  currentLotteryId: bigint;
}

export function LotteryList({ currentLotteryId }: LotteryListProps) {
  const lotteryIds = Array.from({ length: Number(currentLotteryId) }, (_, i) => BigInt(i));

  return (
    <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-6">
      {lotteryIds.map((id) => (
        <LotteryItem key={id.toString()} lotteryId={id} />
      ))}
    </div>
  );
}
