'use client';

import { WalletButton } from '../../components/WalletButton';
import Link from 'next/link';
import { useAccount } from 'wagmi';

export default function Profile() {
  const { address, isConnected } = useAccount();

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
                  className="text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-gray-100"
                >
                  Lotteries
                </Link>
                <Link
                  href="/profile"
                  className="text-primary font-semibold border-b-2 border-primary pb-1"
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
        {!isConnected ? (
          <div className="text-center py-16">
            <h2 className="text-2xl font-bold mb-4">
              Connect your wallet to view your profile
            </h2>
            <p className="text-gray-600 dark:text-gray-400 mb-8">
              See your lottery participation history, token allocations, and
              winnings
            </p>
          </div>
        ) : (
          <div>
            <div className="mb-8">
              <h1 className="text-4xl font-bold mb-2">My Profile</h1>
              <p className="text-gray-600 dark:text-gray-400 font-mono">
                {address}
              </p>
            </div>

            <div className="grid md:grid-cols-2 gap-6 mb-8">
              <div className="border border-gray-200 dark:border-gray-800 rounded-lg p-6">
                <h3 className="text-lg font-semibold mb-4">
                  Participation Stats
                </h3>
                <div className="space-y-3">
                  <div className="flex justify-between">
                    <span className="text-gray-600 dark:text-gray-400">
                      Lotteries Joined:
                    </span>
                    <span className="font-semibold">0</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-gray-600 dark:text-gray-400">
                      Total Tokens Used:
                    </span>
                    <span className="font-semibold">0</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-gray-600 dark:text-gray-400">
                      Items Won:
                    </span>
                    <span className="font-semibold">0</span>
                  </div>
                </div>
              </div>

              <div className="border border-gray-200 dark:border-gray-800 rounded-lg p-6">
                <h3 className="text-lg font-semibold mb-4">Recent Activity</h3>
                <p className="text-gray-600 dark:text-gray-400 text-sm">
                  No recent activity
                </p>
              </div>
            </div>

            <div className="border border-gray-200 dark:border-gray-800 rounded-lg p-6">
              <h3 className="text-lg font-semibold mb-4">Active Lotteries</h3>
              <p className="text-gray-600 dark:text-gray-400 text-sm">
                You haven't joined any active lotteries yet
              </p>
              <Link
                href="/lottery"
                className="inline-block mt-4 px-6 py-2 bg-primary text-white rounded-lg font-semibold hover:bg-blue-600 transition-colors"
              >
                Browse Lotteries
              </Link>
            </div>
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
