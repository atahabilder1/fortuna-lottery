'use client';

import Link from 'next/link';

interface LotteryCardProps {
  lotteryId: number;
  name: string;
  itemCount: number;
  tokensPerParticipant: number;
  startTime: number;
  endTime: number;
  isActive: boolean;
}

export function LotteryCard({
  lotteryId,
  name,
  itemCount,
  tokensPerParticipant,
  startTime,
  endTime,
  isActive,
}: LotteryCardProps) {
  const now = Date.now() / 1000;
  const hasStarted = now >= startTime;
  const hasEnded = now > endTime;

  const getStatus = () => {
    if (!isActive) return 'Ended';
    if (!hasStarted) return 'Upcoming';
    if (hasEnded) return 'Ended';
    return 'Active';
  };

  const getStatusColor = () => {
    const status = getStatus();
    if (status === 'Active') return 'bg-green-500';
    if (status === 'Upcoming') return 'bg-blue-500';
    return 'bg-gray-500';
  };

  const formatDate = (timestamp: number) => {
    return new Date(timestamp * 1000).toLocaleDateString('en-US', {
      month: 'short',
      day: 'numeric',
      year: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    });
  };

  return (
    <div className="border border-gray-200 dark:border-gray-800 rounded-lg p-6 hover:shadow-lg transition-shadow">
      <div className="flex justify-between items-start mb-4">
        <h3 className="text-xl font-bold">{name}</h3>
        <span
          className={`px-3 py-1 text-xs font-semibold text-white rounded-full ${getStatusColor()}`}
        >
          {getStatus()}
        </span>
      </div>

      <div className="space-y-2 mb-6">
        <div className="flex justify-between text-sm">
          <span className="text-gray-600 dark:text-gray-400">Items:</span>
          <span className="font-medium">{itemCount}</span>
        </div>
        <div className="flex justify-between text-sm">
          <span className="text-gray-600 dark:text-gray-400">
            Tokens per participant:
          </span>
          <span className="font-medium">{tokensPerParticipant}</span>
        </div>
        <div className="flex justify-between text-sm">
          <span className="text-gray-600 dark:text-gray-400">Starts:</span>
          <span className="font-medium text-xs">{formatDate(startTime)}</span>
        </div>
        <div className="flex justify-between text-sm">
          <span className="text-gray-600 dark:text-gray-400">Ends:</span>
          <span className="font-medium text-xs">{formatDate(endTime)}</span>
        </div>
      </div>

      <Link
        href={`/lottery/${lotteryId}`}
        className="block w-full text-center px-4 py-2 bg-primary text-white rounded-lg font-semibold hover:bg-blue-600 transition-colors"
      >
        View Lottery
      </Link>
    </div>
  );
}
