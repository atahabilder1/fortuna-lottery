'use client';

import { useItemInfo, useParticipantTokensOnItem, usePlaceTokens } from '@/lib/contracts';
import { useAccount } from 'wagmi';
import { useState, useEffect } from 'react';

interface LotteryItemProps {
  lotteryId: bigint;
  itemId: number;
  isRegistered: boolean;
  availableTokens: number;
  onTokensPlaced: () => void;
}

function LotteryItemCard({
  lotteryId,
  itemId,
  isRegistered,
  availableTokens,
  onTokensPlaced,
}: LotteryItemProps) {
  const { address } = useAccount();
  const { data: itemInfo, isLoading } = useItemInfo(lotteryId, BigInt(itemId));
  const { data: participantTokens, refetch: refetchTokens } = useParticipantTokensOnItem(
    lotteryId,
    address,
    BigInt(itemId)
  );

  const { placeTokens, isPending, isConfirming, isSuccess, error } = usePlaceTokens();

  const [tokenAmount, setTokenAmount] = useState(1);

  useEffect(() => {
    if (isSuccess) {
      refetchTokens();
      onTokensPlaced();
      setTokenAmount(1);
    }
  }, [isSuccess, refetchTokens, onTokensPlaced]);

  if (isLoading || !itemInfo) {
    return (
      <div className="border border-gray-200 dark:border-gray-800 rounded-lg p-6 animate-pulse">
        <div className="h-6 bg-gray-200 dark:bg-gray-800 rounded mb-4"></div>
        <div className="h-4 bg-gray-200 dark:bg-gray-800 rounded mb-2"></div>
        <div className="h-4 bg-gray-200 dark:bg-gray-800 rounded"></div>
      </div>
    );
  }

  const [name, description, totalTokens, winner, winnerSelected] = itemInfo;
  const userTokensOnItem = participantTokens ? Number(participantTokens) : 0;

  const handlePlaceTokens = () => {
    if (tokenAmount > 0 && tokenAmount <= availableTokens) {
      placeTokens(lotteryId, BigInt(itemId), BigInt(tokenAmount));
    }
  };

  const winPercentage =
    Number(totalTokens) > 0 && userTokensOnItem > 0
      ? ((userTokensOnItem / Number(totalTokens)) * 100).toFixed(2)
      : '0';

  return (
    <div className="border border-gray-200 dark:border-gray-800 rounded-lg p-6 hover:border-primary transition-colors">
      <div className="flex justify-between items-start mb-4">
        <div>
          <h3 className="text-xl font-bold mb-1">{name}</h3>
          <p className="text-gray-600 dark:text-gray-400 text-sm">{description}</p>
        </div>
        {winnerSelected && (
          <span className="px-3 py-1 bg-yellow-100 dark:bg-yellow-900/30 text-yellow-700 dark:text-yellow-400 rounded-full text-xs font-semibold">
            Winner Selected
          </span>
        )}
      </div>

      <div className="mb-4 space-y-2">
        <div className="flex justify-between text-sm">
          <span className="text-gray-600 dark:text-gray-400">Total Tokens:</span>
          <span className="font-semibold">{Number(totalTokens)}</span>
        </div>
        <div className="flex justify-between text-sm">
          <span className="text-gray-600 dark:text-gray-400">Your Tokens:</span>
          <span className="font-semibold">{userTokensOnItem}</span>
        </div>
        {userTokensOnItem > 0 && (
          <div className="flex justify-between text-sm">
            <span className="text-gray-600 dark:text-gray-400">Win Chance:</span>
            <span className="font-semibold text-primary">{winPercentage}%</span>
          </div>
        )}
      </div>

      {winnerSelected && (
        <div className="mb-4 p-3 bg-yellow-50 dark:bg-yellow-900/20 rounded-lg">
          <p className="text-sm font-medium text-gray-900 dark:text-gray-100">Winner:</p>
          <p className="text-xs font-mono text-gray-600 dark:text-gray-400 break-all">
            {winner}
          </p>
        </div>
      )}

      {isRegistered && !winnerSelected && (
        <div className="space-y-3">
          <div className="flex gap-2">
            <input
              type="number"
              min="1"
              max={availableTokens}
              value={tokenAmount}
              onChange={(e) => setTokenAmount(Math.max(1, Math.min(availableTokens, parseInt(e.target.value) || 1)))}
              className="flex-1 px-3 py-2 border border-gray-300 dark:border-gray-700 rounded-lg bg-white dark:bg-gray-900 text-gray-900 dark:text-gray-100"
              disabled={availableTokens === 0 || isPending || isConfirming}
            />
            <button
              onClick={handlePlaceTokens}
              disabled={availableTokens === 0 || isPending || isConfirming || tokenAmount < 1}
              className="px-4 py-2 bg-primary text-white rounded-lg font-semibold hover:bg-blue-600 transition-colors disabled:opacity-50 disabled:cursor-not-allowed whitespace-nowrap"
            >
              {isPending || isConfirming ? 'Placing...' : 'Place Tokens'}
            </button>
          </div>
          {error && (
            <p className="text-red-600 dark:text-red-400 text-xs">
              Error: {(error as Error).message}
            </p>
          )}
          {availableTokens === 0 && (
            <p className="text-gray-600 dark:text-gray-400 text-xs">
              No tokens available
            </p>
          )}
        </div>
      )}
    </div>
  );
}

interface LotteryItemsProps {
  lotteryId: bigint;
  itemCount: number;
  isRegistered: boolean;
  availableTokens: number;
}

export function LotteryItems({
  lotteryId,
  itemCount,
  isRegistered,
  availableTokens,
}: LotteryItemsProps) {
  const [refreshKey, setRefreshKey] = useState(0);

  const handleTokensPlaced = () => {
    setRefreshKey((prev) => prev + 1);
  };

  const itemIds = Array.from({ length: itemCount }, (_, i) => i);

  return (
    <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-6">
      {itemIds.map((itemId) => (
        <LotteryItemCard
          key={`${itemId}-${refreshKey}`}
          lotteryId={lotteryId}
          itemId={itemId}
          isRegistered={isRegistered}
          availableTokens={availableTokens}
          onTokensPlaced={handleTokensPlaced}
        />
      ))}
    </div>
  );
}
