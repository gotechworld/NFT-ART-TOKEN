## ArtToken (ERC721) - Secure Foundry Project

A secure, fully tested, and CI/CD-integrated ERC721 NFT smart contract built with Foundry. This project enforces production-grade security hygiene, including static analysis, fuzz testing, invariant testing, and automated linting.

🛠 **Tech Stack**

+ Framework: [Foundry](https://book.getfoundry.sh/) (Forge, Cast, Chisel)
+ Language: Solidity ^0.8.19
+ Security Tools: Slither, Solhint
+ CI/CD: GitHub Actions
+ Dependencies: OpenZeppelin Contracts v4.4.2

📋 **Prerequisites**

Before you begin, ensure you have the following installed on your machine:

1. **Foundry (Forge, Cast, Anvil)**

```bash
curl -L https://foundry.paradigm.xyz | bashfoundryup
```

2. **Node.js & npm (for Solhint)**

```bash
# Via nvm or directly from nodejs.org
npm install -g solhint
```

3. **Python 3 & pip (for Slither)**

```bash
pip3 install slither-analyzer
```

4. **lcov (for coverage reporting)**

```bash
# macOS
brew install lcov
# Ubunru/Debian
sudo apt-get install lcov
```

🚀 **Installation & Setup**

1. **Clone the repository**

```bash
git clone https://github.com/gotechworld/NFT-ART-TOKEN.git
cd nft-art-token
```

2. **Install Foundry dependencies**

This will fetch the OpenZeppelin contracts into the **lib/** directory.

```bash
forge install OpenZeppelin/openzeppelin-contracts@v4.4.2
```

3. **Set up Local Environment Variables**

Create a `.env` file in the root directory (this is ignored by `.gitignore`) to securely store your testnet secrets for local deployment:

```bash
SEPOLIA_DEPLOYER_KEY="0x_YOUR_WALLET_PRIVATE_KEY"
SEPOLIA_RPC_URL="https://eth-sepolia.g.alchemy.com/v2/YOUR_ALCHEMY_KEY"
ETHERSCAN_API_KEY="YOUR_ETHERSCAN_API_KEY"
TOKEN_NAME="Sepolia Art Project"
TOKEN_SYMBOL="SAP"
```

🏗 **Build**

To compile the smart contracts, run:

```bash
forge build
```

To automatically format the code according to Foundry standards:

```bash
forge fmt
```

🧪 **Testing**

This project includes Unit Tests, Fuzz Tests, and Invariant Tests.

**Run all tests:**

```bash
forge test -vvv
```

**Run only Fuzz Tests:**

```bash
forge test --match-test "testFuzz" -vvv
```

**Run only Invariant Tests:**

```bash
forge test --match-test "invariant" -vvv
```

🔬 **Security & Code Quality**

Before opening a Pull Request, ensure your code passes all security checks.

1. **Linting (Solhint & Forge Formatter)**:

```bash
forge fmt --check
forge fmt
solhint 'src/**/*.sol' --config .solhint.json
```

2. **Static Analysis (Slither)**:

```bash
slither . --config-file slither.config.json
```

3. **Coverage Threshold (Minimum 80%)**:

```bash
bash scripts/check_coverage_threshold.sh 80 coverage-reports
```

⛓ **Deployment (Sepolia Testnet)**

This project includes a deployment script that enforces deployment only to the Sepolia testnet (Chain ID `11155111`).

1. **Load your environment variables**:

```bash
source .env
```

2. **Simulate the deployment (Dry Run)**:

```bash
forge script script/deploy/Deploy.s.sol:DeployScript \
  --rpc-url "$SEPOLIA_RPC_URL" \
  --private-key "$SEPOLIA_DEPLOYER_KEY"
```

3. **Broadcast the deployment & Verify on Etherscan**:

```bash
forge script script/deploy/Deploy.s.sol:DeployScript \
  --rpc-url "$SEPOLIA_RPC_URL" \
  --private-key "$SEPOLIA_DEPLOYER_KEY" \
  --broadcast \
  --verify \
  --etherscan-api-key "$ETHERSCAN_API_KEY" \
  --verifier-url "https://api-sepolia.etherscan.io/api"
```

⚙️ **GitHub CI/CD Setup**

To enable the automated pipeline, you must configure specific environments, secrets, and branch protection rules in your GitHub repository.

1. **GitHub Environments**

Navigate to **Settings > Environments** and create the following two environments:

- **sepolia-audit-approval**: Used for Stage 5 (Manual Review Gate). Under "Required reviewers", add the GitHub usernames or teams responsible for auditing and approving deployments.
- **sepolia**: Used for Stage 6 (Deployment). Also, add "Required reviewers" here to ensure a final manual click is required to execute the deployment script.

2. **GitHub Secrets**

Add the following secrets. For maximum security, add deployment-specific secrets to the **sepolia** environment, while general ones can be repository secrets (**Settings > Secrets and variables > Actions**).

Environment Secrets (for the **sepolia** environment):

 - **SEPOLIA_DEPLOYER_KEY**: The private key of the wallet deploying the contract (must hold Sepolia ETH).
 - **SEPOLIA_RPC_URL**: Your Alchemy/Infura Sepolia RPC endpoint.
 - **ETHERSCAN_API_KEY**: Your Etherscan API key for contract verification.
 - **TOKEN_NAME**: The name of your NFT collection (e.g., "Sepolia Art Project").
 - **TOKEN_SYMBOL**: The symbol of your NFT collection (e.g., "SAP").

3. **Branch Protection Rules**

To enforce the pipeline, go to **Settings > Branches > Add branch protection rule** for the **main** branch:

- **Require status checks to pass before merging**: Require all CI jobs (Lint, Static Analysis, Unit/Invariant, Fuzz/Coverage, Manual Gate, Deployment) to pass.
- **Require pull request reviews before merging**: Require at least 1 approval.
- **Require linear history**: Enforce clean git history.

4. **Pull Request Labels**

Create a label named **override-warnings** in your repository. If a PR introduces Solhint warnings (but no errors), applying this label will allow the CI pipeline to pass, bypassing the warning gate.

📂 **Project Structure**

nft-art-token/
├── .github/
│   ├── workflows/ci.yml        # CI/CD pipeline configuration
│   └── AUDIT_CHECKLIST.md      # Manual review gate checklist
├── script/
│   └── deploy/Deploy.s.sol     # Sepolia deployment script
├── src/
│   └── ArtToken.sol            # Main ERC721 Smart Contract
├── test/
│   ├── ArtToken.t.sol          # Unit & Fuzz tests
│   └── ArtToken.invariants.t.sol # Invariant tests
├── .env                        # Local secrets (Not committed)
├── .gitignore
├── .solhint.json               # Solhint security rules
├── foundry.toml                # Foundry configuration
├── remappings.txt              # Solidity import remappings
└── slither.config.json         # Slither static analysis config

📊 **Executive Security Report**

To ensure full visibility for developers, auditors, and management, this repository automatically generates a polished, executive-friendly HTML security report at the end of every CI/CD run.

**How It Works**

When the Smart Contract CI (Sepolia) workflow finishes (whether it succeeds or fails), a secondary workflow named `Aggregated Security Report` automatically triggers. This workflow:

1. Collects all raw security artifacts generated during the pipeline (Solhint logs, Slither SARIF files, Mythril reports, coverage data, and test logs).
2. Bundles them into a single downloadable ZIP file.
3. Generates a styled `index.html` file that can be opened in any web browser.

**What's Inside the Report?**

The HTML report is designed to be readable for non-technical stakeholders while providing direct links to raw data for engineers. It includes:

- **Build Metadata**: Repository, branch, commit SHA, and final pass/fail status.
- **Introduction**: A brief overview of why smart contract security and CI/CD automation are critical.
- **Vulnerability Classes & Mitigations Matrix**: An educational table detailing the exact vulnerability classes the automated pipeline scans for (e.g., Reentrancy, Access Control, Timestamp Dependence), their severity levels, and the mitigation strategies enforced in the code.
- **CI Pipeline Summary**: A checklist of the security stages executed (Linting, Static Analysis, Mythril Symbolic Execution, Fuzzing, Coverage, etc.).
- **Artifact Index**: A dynamically generated list of all raw reports attached to the build.
- **Executive Summary**: A concluding overview of the defense-in-depth strategy.

**How to Access the Report**

1. Go to the Actions tab in your GitHub repository.
2. Click on the Aggregated Security Report workflow (on the left sidebar).
3. Select the latest run.
4. Scroll down to the Artifacts section at the bottom of the summary page.
5. Download the security-report-build-<run_id> ZIP file.
6. Extract the ZIP and open security-summary/index.html in your web browser.
