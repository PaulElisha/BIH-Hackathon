// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.22;

library LibFeasibility {

    struct ProjectFeasibility {
        address owner;
        uint256 feasibilityScore;
    }

    mapping(address => ProjectFeasibility) public projectFeasibilities;

    function calculateFeasibilityScore(
        uint256 potentialRevenue,
        uint256 userAdoptionRate,
        uint256 marketSize,
        uint256 developmentCost,
        uint256 operationalCost
    ) external pure returns (uint256 feasibilityScore) {
        // Multiply all values by a sufficiently large factor to convert them into integers
        uint256 factor = 10**18;

        // Perform the calculation
        uint256 numerator = potentialRevenue * userAdoptionRate * marketSize * factor;
        uint256 denominator = (developmentCost + operationalCost) * factor;

        // Calculate the feasibility score and return it
        feasibilityScore = numerator / denominator;
    }

     function calculateNPV(
        uint[] memory cashFlows,
        uint discountRate,
        uint initialInvestment
    ) public pure returns (int) {
        int npv = 0;
        for (uint i = 0; i < cashFlows.length; i++) {
            npv += int(cashFlows[i]) / int((1 + discountRate) ** i);
        }
        return npv - int(initialInvestment);
    }

    function calculateROI(uint netProfit, uint initialInvestment) external pure returns (uint) {
        require(initialInvestment > 0, "Initial investment must be greater than zero");
        return (netProfit * 100) / initialInvestment;
    }

    function setFeasibilityScore(address project, uint256 score) external {
        require(msg.sender == project, "Only project owner can set feasibility score");
        
        projectFeasibilities[project] = ProjectFeasibility(msg.sender, score);
    }
    
    // Function to get the feasibility score of a project
    function getFeasibilityScore(address project) external view returns (uint256) {
        return projectFeasibilities[project].feasibilityScore;
    }

    function calculateRANPV(
        int[] memory cashFlows,
        int discountRate,
        int[] memory riskPremiums,
        int initialInvestment
    ) public pure returns (int) {
        require(cashFlows.length == riskPremiums.length, "Arrays length mismatch");

        int ranpv = 0;
        for (uint i = 0; i < cashFlows.length; i++) {
            int discountedCashFlow = cashFlows[i] / ((1 + discountRate + riskPremiums[i]) ** i);
            ranpv += discountedCashFlow;
        }
        ranpv -= initialInvestment;
        return ranpv;
    }

    function calculateFeasibilityScore(
        uint[] memory factors,
        uint[] memory weights
    ) public pure returns (uint) {
        require(factors.length == weights.length, "Factors and weights length mismatch");
        
        uint weightedSum = 0;
        uint totalWeight = 0;
        
        // Calculate weighted sum
        for (uint i = 0; i < factors.length; i++) {
            weightedSum += factors[i] * weights[i];
            totalWeight += weights[i];
        }
        
        // Avoid division by zero
        require(totalWeight > 0, "Total weight must be greater than zero");
        
        // Calculate feasibility score
        return (weightedSum * 100) / totalWeight; // Multiply by 100 for better precision
    }

     function calculateNPV(uint[] memory cashFlows, uint initialInvestment, uint discountRate) public pure returns (int) {
        int npv = 0;
        for (uint i = 0; i < cashFlows.length; i++) {
            npv += int(cashFlows[i]) / int((1 + discountRate) ** (i + 1));
        }
        return npv - int(initialInvestment);
    }

    function calculateIRR(uint[] memory cashFlows, uint initialInvestment, uint guess) public pure returns (uint) {
        uint npv;
        uint irr = guess;
        uint epsilon = 1;
        while (epsilon > 0) {
            npv = 0;
            for (uint i = 0; i < cashFlows.length; i++) {
                npv += cashFlows[i] / (10 * 18 * (1 + irr) * i);
            }
            epsilon = npv > initialInvestment ? npv - initialInvestment : initialInvestment - npv;
            irr += epsilon / 2;
        }
        return irr;
    }

    function calculatePaybackPeriod(uint[] memory cashFlows, uint initialInvestment) public pure returns (uint) {
        uint cumulativeCashFlows = 0;
        uint paybackPeriod;
        for (uint i = 0; i < cashFlows.length; i++) {
            cumulativeCashFlows += cashFlows[i];
            if (cumulativeCashFlows >= initialInvestment) {
                paybackPeriod = i + 1;
                break;
            }
        }
        return paybackPeriod;
    }

    function calculateFeasibilityScore(
        uint256 potentialRevenue,
        uint256 userAdoptionRate,
        uint256 marketSize,
        uint256 developmentCost,
        uint256 operationalCost
    ) public pure returns (uint256 feasibilityScore) {
        // Adjusting for decimals by multiplying by a factor (e.g., 10^18)
        uint256 factor = 10**18;

        // Perform the calculation
        feasibilityScore = (
            (potentialRevenue * factor) *
            (userAdoptionRate * factor) *
            (marketSize * factor)
        ) / (
            (developmentCost * factor) +
            (operationalCost * factor)
        );

        // Divide by the factor to get the final result
        feasibilityScore /= factor;
    }
}