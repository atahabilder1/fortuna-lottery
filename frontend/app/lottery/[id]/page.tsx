'use client';

import { WalletButton } from '../../../components/WalletButton';
import {
  useLotteryInfo,
  useParticipantInfo,
  useRegisterParticipant,
  useParticipantCount,
} from '@/lib/contracts';
import Link from 'next/link';
import { useParams } from 'next/navigation';
import { useAccount } from 'wagmi';
import { useState, useEffect } from 'react';
import { LotteryItems } from '../../../components/LotteryItems';

export default function LotteryDetailPage() {
  const params = useParams();
  const lotteryId = BigInt(params.id as string);
  const { address, isConnected } = useAccount();

  const { data: lotteryInfo, isLoading: isLoadingLottery } = useLotteryInfo(lotteryId);
  const { data: participantInfo, refetch: refetchParticipant } = useParticipantInfo(
    lotteryId,
    address
  );
  const { data: participantCount } = useParticipantCount(lotteryId);

  const {
    registerParticipant,
    isPending,
    isConfirming,
    isSuccess,
    error,
  } = useRegisterParticipant();

  useEffect(() => {
    if (isSuccess) {
      refetchParticipant();
    }
  }, [isSuccess, refetchParticipant]);

  if (isLoadingLottery) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <p className="text-gray-600 dark:text-gray-400">Loading lottery...</p>
      </div>
    );
  }

  if (!lotteryInfo) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="text-center">
          <p className="text-red-600 dark:text-red-400 mb-4">Lottery not found</p>
          <Link href="/lottery" className="text-primary hover:underline">
            Back to Lotteries
          </Link>
        </div>
      </div>
    );
  }

  const [name, tokensPerParticipant, startTime, endTime, itemCount, isActive] = lotteryInfo;
  const isRegistered = participantInfo ? participantInfo[2] : false;
  const totalTokens = participantInfo ? Number(participantInfo[0]) : 0;
  const tokensUsed = participantInfo ? Number(participantInfo[1]) : 0;

  const now = Math.floor(Date.now() / 1000);
  const hasStarted = now >= Number(startTime);
  const hasEnded = now >= Number(endTime);

  const handleRegister = () => {
    registerParticipant(lotteryId);
  };

  return (
    <div className="min-h-screen flex flex-col">
      <header className="border-b border-gray-200 dark:border-gray-800">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-4">
          <div className="flex justify-between items-center">
            <div className="flex items-center gap-8">
              <Link href="/" className="text-2xl font-bold">
                Fortuna Lottery
              </Link>
              <nav className="flex gap-6">
                <Link
                  href="/lottery"
                  className="text-primary font-semibold border-b-2 border-primary pb-1"
                >
                  Lotteries
                </Link>
                <Link
                  href="/profile"
                  className="text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-gray-100"
                >
                  Profile
                </Link>
              </nav>
            </div>
            <WalletButton />
          </div>
        </div>
      </header>

      <main className="flex-1 max-w-7xl w-full mx-auto px-4 sm:px-6 lg:px-8 py-12">
        <div className="mb-6">
          <Link
            href="/lottery"
            className="text-primary hover:underline inline-flex items-center gap-2 mb-4"
          >
            ← Back to Lotteries
          </Link>
          <h1 className="text-4xl font-bold mb-2">{name}</h1>
          <div className="flex items-center gap-4">
            {isActive && hasStarted && !hasEnded ? (
              <span className="px-3 py-1 bg-green-100 dark:bg-green-900/30 text-green-700 dark:text-green-400 rounded-full text-sm font-semibold">
                Active
              </span>
            ) : hasEnded ? (
              <span className="px-3 py-1 bg-gray-100 dark:bg-gray-800 text-gray-700 dark:text-gray-400 rounded-full text-sm font-semibold">
                Ended
              </span>
            ) : (
              <span className="px-3 py-1 bg-blue-100 dark:bg-blue-900/30 text-blue-700 dark:text-blue-400 rounded-full text-sm font-semibold">
                Upcoming
              </span>
            )}
          </div>
        </div>

        <div className="grid md:grid-cols-3 gap-6 mb-8">
          <div className="border border-gray-200 dark:border-gray-800 rounded-lg p-6">
            <h3 className="text-sm font-medium text-gray-600 dark:text-gray-400 mb-2">
              Total Items
            </h3>
            <p className="text-3xl font-bold">{Number(itemCount)}</p>
          </div>

          <div className="border border-gray-200 dark:border-gray-800 rounded-lg p-6">
            <h3 className="text-sm font-medium text-gray-600 dark:text-gray-400 mb-2">
              Tokens Per Participant
            </h3>
            <p className="text-3xl font-bold">{Number(tokensPerParticipant)}</p>
          </div>

          <div className="border border-gray-200 dark:border-gray-800 rounded-lg p-6">
            <h3 className="text-sm font-medium text-gray-600 dark:text-gray-400 mb-2">
              Total Participants
            </h3>
            <p className="text-3xl font-bold">{Number(participantCount || 0)}</p>
          </div>
        </div>

        <div className="grid md:grid-cols-2 gap-6 mb-8">
          <div className="border border-gray-200 dark:border-gray-800 rounded-lg p-6">
            <h3 className="text-sm font-medium text-gray-600 dark:text-gray-400 mb-2">
              Start Time
            </h3>
            <p className="text-lg font-semibold">
              {new Date(Number(startTime) * 1000).toLocaleString()}
            </p>
          </div>

          <div className="border border-gray-200 dark:border-gray-800 rounded-lg p-6">
            <h3 className="text-sm font-medium text-gray-600 dark:text-gray-400 mb-2">
              End Time
            </h3>
            <p className="text-lg font-semibold">
              {new Date(Number(endTime) * 1000).toLocaleString()}
            </p>
          </div>
        </div>

        {!isConnected ? (
          <div className="border border-gray-200 dark:border-gray-800 rounded-lg p-8 text-center mb-8">
            <p className="text-gray-600 dark:text-gray-400 mb-4">
              Connect your wallet to participate in this lottery
            </p>
          </div>
        ) : !isRegistered ? (
          <div className="border border-blue-200 dark:border-blue-800 bg-blue-50 dark:bg-blue-900/20 rounded-lg p-8 text-center mb-8">
            <h3 className="text-xl font-bold mb-2">Join this lottery</h3>
            <p className="text-gray-600 dark:text-gray-400 mb-4">
              Register to receive {Number(tokensPerParticipant)} tokens and start participating
            </p>
            <button
              onClick={handleRegister}
              disabled={isPending || isConfirming || hasEnded || !hasStarted}
              className="px-6 py-3 bg-primary text-white rounded-lg font-semibold hover:bg-blue-600 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
            >
              {isPending || isConfirming
                ? 'Registering...'
                : hasEnded
                ? 'Lottery Ended'
                : !hasStarted
                ? 'Lottery Not Started'
                : 'Register Now'}
            </button>
            {error && (
              <p className="text-red-600 dark:text-red-400 text-sm mt-2">
                Error: {(error as Error).message}
              </p>
            )}
          </div>
        ) : (
          <div className="border border-green-200 dark:border-green-800 bg-green-50 dark:bg-green-900/20 rounded-lg p-6 mb-8">
            <div className="flex justify-between items-center">
              <div>
                <h3 className="text-lg font-bold mb-1">You're registered!</h3>
                <p className="text-gray-600 dark:text-gray-400 text-sm">
                  You have {totalTokens - tokensUsed} tokens available out of {totalTokens} total
                </p>
              </div>
              <div className="text-right">
                <p className="text-3xl font-bold text-green-600 dark:text-green-400">
                  {totalTokens - tokensUsed}
                </p>
                <p className="text-sm text-gray-600 dark:text-gray-400">tokens left</p>
              </div>
            </div>
          </div>
        )}

        <div className="border-t border-gray-200 dark:border-gray-800 pt-8">
          <h2 className="text-2xl font-bold mb-6">Lottery Items</h2>
          <LotteryItems
            lotteryId={lotteryId}
            itemCount={Number(itemCount)}
            isRegistered={isRegistered}
            availableTokens={totalTokens - tokensUsed}
          />
        </div>
      </main>

      <footer className="border-t border-gray-200 dark:border-gray-800 py-6">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 text-center text-gray-600 dark:text-gray-400">
          <p>Built with Solidity, Foundry, Next.js 14, and Chainlink VRF</p>
        </div>
      </footer>
    </div>
  );
}
