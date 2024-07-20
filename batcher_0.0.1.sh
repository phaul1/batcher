#!/bin/bash

# Function to send transactions using ethers.js
send_transactions() {
  local private_key=$1
  local rpc_url=$2
  local chain_id=$3
  local gas_limit=$4
  local max_fee_per_gas=$5
  local max_priority_fee_per_gas=$6
  local to_address=$7
  local data=$8

  cat <<EOF > sendTx.js
const { ethers } = require('ethers');

const privateKey = '${private_key}';
const provider = new ethers.providers.JsonRpcProvider('${rpc_url}');
const wallet = new ethers.Wallet(privateKey, provider);

const tx = {
  to: '${to_address}',
  data: '${data}',
  chainId: ${chain_id},
  gasLimit: ethers.utils.hexlify(${gas_limit}),
  maxFeePerGas: ethers.utils.parseUnits('${max_fee_per_gas}', 'gwei'),
  maxPriorityFeePerGas: ethers.utils.parseUnits('${max_priority_fee_per_gas}', 'gwei'),
  type: 2
};

async function sendTransaction() {
  for (let i = 0; i < 5; i++) {
    try {
      const txResponse = await wallet.sendTransaction(tx);
      console.log('Tx Hash:', txResponse.hash);
      const receipt = await txResponse.wait();
      console.log('Transaction was mined in block:', receipt.blockNumber);
      break;  // Exit the loop if transaction is successful
    } catch (error) {
      console.error('Error sending transaction, attempt', i + 1, 'of 5:', error);
      if (error.code === 'SERVER_ERROR' && error.status === 503) {
        console.log('Retrying in 5 seconds...');
        await new Promise(resolve => setTimeout(resolve, 5000));
      } else {
        break;  // Exit the loop for non-server errors
      }
    }
  }
}

sendTransaction();
EOF

  node sendTx.js
}

# Define the variables
PRIVATE_KEY="<your-private-key>"
RPC_URL="https://rpc-testnet.unit0.dev"
CHAIN_ID=88817
GAS_LIMIT=250000
MAX_FEE_PER_GAS=20  # in Gwei
MAX_PRIORITY_FEE_PER_GAS=2  # in Gwei
TO_ADDRESS="0x85dD5EfC05798958eAf19A62f7c5C083983E1C85"
DATA="0x7ff36ab5000000000000000000000000000000000000000000000000000000000000a8210000000000000000000000000000000000000000000000000000000000000080000000000000000000000000d8f09a9b6bac0b86278aac437c647255c2815afb00000000000000000000000000000000000000000000000000000000669aff8c000000000000000000000000000000000000000000000000000000000000000200000000000000000000000097f1f1b1a35b3bdd5642b7d6d497e8dc5eb4d7cd000000000000000000000000783777f267fa1e2c95c202a0e3da7107c0fafe8b"

# Send the transaction
send_transactions "$PRIVATE_KEY" "$RPC_URL" "$CHAIN_ID" "$GAS_LIMIT" "$MAX_FEE_PER_GAS" "$MAX_PRIORITY_FEE_PER_GAS" "$TO_ADDRESS" "$DATA"
