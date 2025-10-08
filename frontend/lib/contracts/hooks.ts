import { useReadContract, useWriteContract, useWaitForTransactionReceipt } from 'wagmi';
import { FortunaLotteryABI } from './FortunaLotteryABI';
import { CONTRACT_CONFIG } from './config';
import type { LotteryInfo, ItemInfo, ParticipantInfo } from './types';

export function useCurrentLotteryId() {
  return useReadContract({
    ...CONTRACT_CONFIG,
    abi: FortunaLotteryABI,
    functionName: 'currentLotteryId',
  });
}

export function useLotteryInfo(lotteryId: bigint | undefined) {
  return useReadContract({
    ...CONTRACT_CONFIG,
    abi: FortunaLotteryABI,
    functionName: 'getLotteryInfo',
    args: lotteryId !== undefined ? [lotteryId] : undefined,
    query: {
      enabled: lotteryId !== undefined,
    },
  });
}

export function useItemInfo(lotteryId: bigint | undefined, itemId: bigint | undefined) {
  return useReadContract({
    ...CONTRACT_CONFIG,
    abi: FortunaLotteryABI,
    functionName: 'getItemInfo',
    args: lotteryId !== undefined && itemId !== undefined ? [lotteryId, itemId] : undefined,
    query: {
      enabled: lotteryId !== undefined && itemId !== undefined,
    },
  });
}

export function useParticipantInfo(
  lotteryId: bigint | undefined,
  participant: `0x${string}` | undefined
) {
  return useReadContract({
    ...CONTRACT_CONFIG,
    abi: FortunaLotteryABI,
    functionName: 'getParticipantInfo',
    args: lotteryId !== undefined && participant ? [lotteryId, participant] : undefined,
    query: {
      enabled: lotteryId !== undefined && participant !== undefined,
    },
  });
}

export function useParticipantCount(lotteryId: bigint | undefined) {
  return useReadContract({
    ...CONTRACT_CONFIG,
    abi: FortunaLotteryABI,
    functionName: 'getParticipantCount',
    args: lotteryId !== undefined ? [lotteryId] : undefined,
    query: {
      enabled: lotteryId !== undefined,
    },
  });
}

export function useParticipantTokensOnItem(
  lotteryId: bigint | undefined,
  participant: `0x${string}` | undefined,
  itemId: bigint | undefined
) {
  return useReadContract({
    ...CONTRACT_CONFIG,
    abi: FortunaLotteryABI,
    functionName: 'getParticipantTokensOnItem',
    args:
      lotteryId !== undefined && participant && itemId !== undefined
        ? [lotteryId, participant, itemId]
        : undefined,
    query: {
      enabled: lotteryId !== undefined && participant !== undefined && itemId !== undefined,
    },
  });
}

export function useIsLotteryActive(lotteryId: bigint | undefined) {
  return useReadContract({
    ...CONTRACT_CONFIG,
    abi: FortunaLotteryABI,
    functionName: 'isLotteryActive',
    args: lotteryId !== undefined ? [lotteryId] : undefined,
    query: {
      enabled: lotteryId !== undefined,
    },
  });
}

export function useRegisterParticipant() {
  const { data: hash, writeContract, isPending, error } = useWriteContract();

  const registerParticipant = (lotteryId: bigint) => {
    writeContract({
      ...CONTRACT_CONFIG,
      abi: FortunaLotteryABI,
      functionName: 'registerParticipant',
      args: [lotteryId],
    });
  };

  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({
    hash,
  });

  return {
    registerParticipant,
    hash,
    isPending,
    isConfirming,
    isSuccess,
    error,
  };
}

export function usePlaceTokens() {
  const { data: hash, writeContract, isPending, error } = useWriteContract();

  const placeTokens = (lotteryId: bigint, itemId: bigint, tokenAmount: bigint) => {
    writeContract({
      ...CONTRACT_CONFIG,
      abi: FortunaLotteryABI,
      functionName: 'placeTokens',
      args: [lotteryId, itemId, tokenAmount],
    });
  };

  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({
    hash,
  });

  return {
    placeTokens,
    hash,
    isPending,
    isConfirming,
    isSuccess,
    error,
  };
}

export function usePlaceTokensBatch() {
  const { data: hash, writeContract, isPending, error } = useWriteContract();

  const placeTokensBatch = (lotteryId: bigint, itemIds: bigint[], tokenAmounts: bigint[]) => {
    writeContract({
      ...CONTRACT_CONFIG,
      abi: FortunaLotteryABI,
      functionName: 'placeTokensBatch',
      args: [lotteryId, itemIds, tokenAmounts],
    });
  };

  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({
    hash,
  });

  return {
    placeTokensBatch,
    hash,
    isPending,
    isConfirming,
    isSuccess,
    error,
  };
}
