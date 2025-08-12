# Blockchain-Based Public Medical Equipment and Supply Services

A comprehensive smart contract system for managing public medical equipment and supply services on the Stacks blockchain using Clarity.

## System Overview

This system consists of five interconnected smart contracts that manage the complete lifecycle of medical equipment rental, maintenance, and emergency deployment:

### 1. Medical Equipment Rental Licensing Contract (`equipment-licensing.clar`)
- Issues and manages permits for businesses renting medical equipment
- Tracks licensing status, expiration dates, and compliance
- Manages equipment categories (wheelchairs, hospital beds, medical devices)
- Handles license renewals and revocations

### 2. Sterilization Compliance Monitoring Contract (`sterilization-compliance.clar`)
- Ensures proper cleaning and sterilization of reusable medical equipment
- Tracks sterilization records and compliance status
- Manages sterilization protocols and verification
- Issues compliance certificates

### 3. Insurance Coordination Contract (`insurance-coordination.clar`)
- Facilitates billing and payment through health insurance
- Manages insurance provider relationships
- Processes claims and reimbursements
- Tracks payment status and coverage verification

### 4. Maintenance and Calibration Contract (`maintenance-calibration.clar`)
- Ensures medical equipment is properly maintained and calibrated
- Schedules regular maintenance and calibration checks
- Tracks equipment accuracy and performance metrics
- Manages maintenance records and certifications

### 5. Emergency Supply Coordination Contract (`emergency-coordination.clar`)
- Manages rapid deployment of medical equipment during health emergencies
- Coordinates emergency response and resource allocation
- Tracks emergency inventory and availability
- Handles priority distribution during crises

## Key Features

- **Decentralized Management**: All equipment tracking and compliance managed on-chain
- **Transparency**: Public visibility of equipment status, compliance, and availability
- **Automated Compliance**: Smart contract enforcement of regulations and standards
- **Emergency Response**: Rapid coordination during health emergencies
- **Insurance Integration**: Streamlined billing and reimbursement processes

## Contract Architecture

Each contract operates independently while maintaining data consistency through standardized data structures and validation rules. The system uses:

- **Principal-based Access Control**: Different roles for providers, regulators, and emergency coordinators
- **Time-based Validations**: Automatic expiration handling for licenses and certifications
- **Status Tracking**: Comprehensive state management for all equipment and processes
- **Error Handling**: Robust error codes and validation throughout

## Data Types

### Equipment Categories
- `wheelchair`: Manual and electric wheelchairs
- `hospital-bed`: Adjustable hospital beds and accessories
- `medical-device`: Specialized medical equipment (monitors, pumps, etc.)
- `emergency-supply`: Critical supplies for emergency deployment

### Status Types
- `active`: Currently operational and compliant
- `inactive`: Not currently in service
- `maintenance`: Under maintenance or repair
- `expired`: License or certification expired
- `emergency`: Reserved for emergency use

## Getting Started

### Prerequisites
- Clarinet CLI installed
- Node.js and npm for testing
- Stacks wallet for deployment

### Installation

\`\`\`bash
# Clone the repository
git clone <repository-url>
cd medical-equipment-blockchain

# Install dependencies
npm install

# Run tests
npm test

# Deploy contracts (testnet)
clarinet deploy --testnet
\`\`\`

### Testing

The system includes comprehensive tests using Vitest:

\`\`\`bash
# Run all tests
npm test

# Run specific contract tests
npm test equipment-licensing
npm test sterilization-compliance
npm test insurance-coordination
npm test maintenance-calibration
npm test emergency-coordination
\`\`\`

## Usage Examples

### Issuing Equipment License
\`\`\`clarity
(contract-call? .equipment-licensing issue-license
'SP1HTBVD3JG9C05J7HBJTHGR0GGW7KX17ECNWWALK
"wheelchair"
u365)
\`\`\`

### Recording Sterilization
\`\`\`clarity
(contract-call? .sterilization-compliance record-sterilization
u1
"autoclave-protocol-1"
u1640995200)
\`\`\`

### Processing Insurance Claim
\`\`\`clarity
(contract-call? .insurance-coordination process-claim
u1
'SP2HTBVD3JG9C05J7HBJTHGR0GGW7KX17ECNWWALK
u50000)
\`\`\`

## Security Considerations

- All contracts implement proper access controls
- Input validation prevents malicious data entry
- Time-based validations ensure compliance with regulations
- Emergency functions include additional security measures

## Compliance

This system is designed to support compliance with:
- FDA medical device regulations
- Healthcare facility licensing requirements
- Insurance billing standards
- Emergency response protocols

## Contributing

Please read the PR-DETAILS.md file for information about contributing to this project.

## License

This project is licensed under the MIT License - see the LICENSE file for details.
