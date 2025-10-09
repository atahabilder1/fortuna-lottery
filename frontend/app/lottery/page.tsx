'use client';

import { WalletButton } from '../../components/WalletButton';
import { LotteryCard } from '../../components/LotteryCard';
import { useCurrentLotteryId } from '@/lib/contracts';
import Link from 'next/link';
import { LotteryList } from '../../components/LotteryList';

export default function LotteryDashboard() {
  const { data: currentLotteryId, isLoading, error } = useCurrentLotteryId();

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
        <div className="mb-8">
          <h1 className="text-4xl font-bold mb-2">Active Lotteries</h1>
          <p className="text-gray-600 dark:text-gray-400">
            Browse and participate in ongoing lotteries
          </p>
        </div>

        {isLoading ? (
          <div className="text-center py-16">
            <p className="text-gray-600 dark:text-gray-400">Loading lotteries...</p>
          </div>
        ) : error ? (
          <div className="text-center py-16">
            <p className="text-red-600 dark:text-red-400 mb-4">Error loading lotteries</p>
            <p className="text-sm text-gray-500 dark:text-gray-500">
              Make sure you are connected to the correct network and the contract is deployed
            </p>
          </div>
        ) : currentLotteryId === undefined || currentLotteryId === 0n ? (
          <div className="text-center py-16">
            <p className="text-gray-600 dark:text-gray-400 mb-4">
              No lotteries available at the moment
            </p>
            <p className="text-sm text-gray-500 dark:text-gray-500">
              Check back later or contact the lottery administrator
            </p>
          </div>
        ) : (
          <LotteryList currentLotteryId={currentLotteryId} />
        )}
      </main>

      <footer className="border-t border-gray-200 dark:border-gray-800 py-6">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 text-center text-gray-600 dark:text-gray-400">
          <p>Built with Solidity, Foundry, Next.js 14, and Chainlink VRF</p>
        </div>
      </footer>
    </div>
  );
}
