import { baseSepolia } from 'wagmi/chains';

export const FORTUNA_LOTTERY_ADDRESS = (process.env.NEXT_PUBLIC_CONTRACT_ADDRESS ||
  '0x0000000000000000000000000000000000000000') as `0x${string}`;

export const SUPPORTED_CHAIN = baseSepolia;

export const CONTRACT_CONFIG = {
  address: FORTUNA_LOTTERY_ADDRESS,
  chainId: SUPPORTED_CHAIN.id,
} as const;
