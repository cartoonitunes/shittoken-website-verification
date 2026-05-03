#!/bin/bash
set -e

ADDRESS="0xdbd98373c5152963ae9940e0477f078bd28ac411"
RPC="${RPC:-https://ethereum-rpc.publicnode.com}"
EXPECTED_SOLC="0.4.11+commit.68ef5810.Darwin.appleclang"

echo "ShitToken (Website) bytecode verification"
echo "========================================="
echo "Address:   $ADDRESS"
echo "Compiler:  native solc $EXPECTED_SOLC"
echo "Optimizer: ON, runs=1"
echo

SOLC_VER=$(solc --version 2>/dev/null | grep -oE '0\.4\.11[^ ]*' | head -1 || true)
if [ -z "$SOLC_VER" ]; then
  echo "ERROR: solc 0.4.11 not found on PATH."
  echo "       Install via solc-select: solc-select install 0.4.11 && solc-select use 0.4.11"
  exit 1
fi
echo "solc version: $SOLC_VER"
if [[ "$SOLC_VER" != *"Darwin.appleclang"* ]]; then
  echo "WARNING: native build differs from expected (Darwin/appleclang). Bytecode may not match exactly."
fi
echo

echo "Fetching on-chain runtime via $RPC ..."
curl -s -X POST -H "Content-Type: application/json" \
  --data "{\"jsonrpc\":\"2.0\",\"method\":\"eth_getCode\",\"params\":[\"$ADDRESS\",\"latest\"],\"id\":1}" \
  "$RPC" \
  | python3 -c "import sys,json; print(json.load(sys.stdin)['result'][2:])" \
  > /tmp/shittoken_web_onchain_runtime.hex
echo "  on-chain runtime: $(wc -c < /tmp/shittoken_web_onchain_runtime.hex) hex chars"

echo "Compiling ShitToken.sol with optimizer ON, runs=1 ..."
solc --optimize --optimize-runs 1 --bin-runtime ShitToken.sol 2>/dev/null \
  | awk '/ShitToken =======/{flag=1;next} flag && /Binary of the runtime part/{getline; print; exit}' \
  > /tmp/shittoken_web_compiled_runtime.hex
echo "  compiled runtime: $(wc -c < /tmp/shittoken_web_compiled_runtime.hex) hex chars"
echo

if diff -q /tmp/shittoken_web_onchain_runtime.hex /tmp/shittoken_web_compiled_runtime.hex > /dev/null 2>&1; then
  echo "EXACT MATCH (perfect — including swarm metadata hash)"
  exit 0
fi

ON=$(cat /tmp/shittoken_web_onchain_runtime.hex | tr -d '\n')
CO=$(cat /tmp/shittoken_web_compiled_runtime.hex | tr -d '\n')

if [ ${#ON} -ne ${#CO} ]; then
  echo "MISMATCH — different lengths (${#ON} vs ${#CO})"
  exit 1
fi

# Metadata trailer for solc 0.4.11 is: a165627a7a72305820<32-byte hash>0029 = 86 hex chars
PREFIX_LEN=$(( ${#ON} - 86 ))
ON_PREFIX="${ON:0:$PREFIX_LEN}"
CO_PREFIX="${CO:0:$PREFIX_LEN}"

if [ "$ON_PREFIX" = "$CO_PREFIX" ]; then
  echo "EXACT BYTECODE MATCH (everything except 32-byte CBOR swarm hash)"
  echo
  echo "  on-chain swarm:  ${ON: -72:64}"
  echo "  compiled swarm:  ${CO: -72:64}"
  echo
  echo "The swarm hash is a content hash of the source file path/metadata, not the"
  echo "code. It cannot be reproduced without the original file layout. The code"
  echo "itself is byte-for-byte identical."
  exit 0
fi

echo "MISMATCH — code differs (not just metadata)"
diff <(echo "$ON_PREFIX") <(echo "$CO_PREFIX") | head -20
exit 1
