'use client';

import { WalletButton } from '../../components/WalletButton';
import { LotteryCard } from '../../components/LotteryCard';
import Link from 'next/link';

export default function LotteryDashboard() {
  // Mock data - In production, fetch from contract
  const lotteries = [
    {
      lotteryId: 0,
      name: 'Summer Raffle 2025',
      itemCount: 5,
      tokensPerParticipant: 10,
      startTime: Math.floor(Date.now() / 1000) - 86400,
      endTime: Math.floor(Date.now() / 1000) + 86400 * 6,
      isActive: true,
    },
    {
      lotteryId: 1,
      name: 'Spring Collection',
      itemCount: 3,
      tokensPerParticipant: 10,
      startTime: Math.floor(Date.now() / 1000) - 86400 * 10,
      endTime: Math.floor(Date.now() / 1000) - 86400,
      isActive: false,
    },
  ];

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

        {lotteries.length === 0 ? (
          <div className="text-center py-16">
            <p className="text-gray-600 dark:text-gray-400 mb-4">
              No lotteries available at the moment
            </p>
            <p className="text-sm text-gray-500 dark:text-gray-500">
              Check back later or contact the lottery administrator
            </p>
          </div>
        ) : (
          <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-6">
            {lotteries.map((lottery) => (
              <LotteryCard key={lottery.lotteryId} {...lottery} />
            ))}
          </div>
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
