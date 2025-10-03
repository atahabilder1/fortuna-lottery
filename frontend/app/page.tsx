import Link from 'next/link';
import { WalletButton } from '../components/WalletButton';

export default function Home() {
  return (
    <div className="min-h-screen flex flex-col">
      <header className="border-b border-gray-200 dark:border-gray-800">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-4 flex justify-between items-center">
          <h1 className="text-2xl font-bold">Fortuna Lottery</h1>
          <WalletButton />
        </div>
      </header>

      <main className="flex-1 flex flex-col items-center justify-center px-4">
        <div className="text-center max-w-4xl">
          <h2 className="text-5xl font-bold mb-6">
            Decentralized Chinese Lottery
          </h2>
          <p className="text-xl text-gray-600 dark:text-gray-400 mb-8">
            Fair, transparent, and provably random lottery system powered by
            Chainlink VRF on Base Sepolia
          </p>

          <div className="grid md:grid-cols-3 gap-6 mb-12">
            <div className="p-6 border border-gray-200 dark:border-gray-800 rounded-lg">
              <h3 className="text-lg font-semibold mb-2">
                Fixed Token Allocation
              </h3>
              <p className="text-gray-600 dark:text-gray-400">
                Each participant receives the same number of tokens to
                distribute across items
              </p>
            </div>

            <div className="p-6 border border-gray-200 dark:border-gray-800 rounded-lg">
              <h3 className="text-lg font-semibold mb-2">
                Weighted Probability
              </h3>
              <p className="text-gray-600 dark:text-gray-400">
                Your chance of winning is proportional to the tokens you place
                on each item
              </p>
            </div>

            <div className="p-6 border border-gray-200 dark:border-gray-800 rounded-lg">
              <h3 className="text-lg font-semibold mb-2">
                Provably Fair
              </h3>
              <p className="text-gray-600 dark:text-gray-400">
                Winners selected using Chainlink VRF v2.5 for verifiable
                randomness
              </p>
            </div>
          </div>

          <div className="flex gap-4 justify-center">
            <Link
              href="/lottery"
              className="px-8 py-3 bg-primary text-white rounded-lg font-semibold hover:bg-blue-600 transition-colors"
            >
              View Lotteries
            </Link>
            <Link
              href="/profile"
              className="px-8 py-3 border border-gray-300 dark:border-gray-700 rounded-lg font-semibold hover:bg-gray-100 dark:hover:bg-gray-800 transition-colors"
            >
              My Profile
            </Link>
          </div>
        </div>
      </main>

      <footer className="border-t border-gray-200 dark:border-gray-800 py-6">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 text-center text-gray-600 dark:text-gray-400">
          <p>Built with Solidity, Foundry, Next.js 14, and Chainlink VRF</p>
          <p className="text-sm mt-2">Base Sepolia Testnet</p>
        </div>
      </footer>
    </div>
  );
}
