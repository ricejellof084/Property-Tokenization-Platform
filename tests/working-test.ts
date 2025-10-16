import { describe, expect, it } from "vitest";
import { Cl } from "@stacks/transactions";

const accounts = simnet.getAccounts();
const address1 = accounts.get("wallet_1")!;
const address2 = accounts.get("wallet_2")!;

const contractName = "Property-Tokenization-Platform";

describe("Property Auction System - Core Functionality", () => {
  it("demonstrates complete auction workflow", () => {
    // 1. Create a property
    const createResult = simnet.callPublicFn(
      contractName,
      "create-property",
      [
        Cl.stringAscii("123 Auction Street"),
        Cl.uint(1000),
        Cl.uint(100),
        Cl.stringAscii("Test property for auction"),
        Cl.stringAscii("Commercial"),
        Cl.uint(5000),
        Cl.uint(2023)
      ],
      address1
    );
    expect(createResult.result).toBeOk(Cl.uint(1));

    // 2. Create an auction for the property
    const auctionResult = simnet.callPublicFn(
      contractName,
      "create-property-auction",
      [Cl.uint(1), Cl.uint(50000), Cl.uint(144)],
      address1
    );
    expect(auctionResult.result).toBeOk(Cl.uint(1));

    // 3. Get auction details to verify it was created
    const auctionDetails = simnet.callReadOnlyFn(
      contractName,
      "get-auction",
      [Cl.uint(1)],
      address1
    );
    expect(auctionDetails.result).toBeSome();

    // 4. Get next auction ID to verify it incremented
    const nextAuctionId = simnet.callReadOnlyFn(
      contractName,
      "get-next-auction-id",
      [],
      address1
    );
    expect(nextAuctionId.result).toBeUint(2);
  });

  it("verifies contract syntax and basic functions", () => {
    expect(simnet.blockHeight).toBeDefined();
    
    // Test basic property creation
    const { result } = simnet.callPublicFn(
      contractName,
      "create-property",
      [
        Cl.stringAscii("456 Test Ave"),
        Cl.uint(500),
        Cl.uint(200),
        Cl.stringAscii("Basic test property"),
        Cl.stringAscii("Residential"),
        Cl.uint(2000),
        Cl.uint(2022)
      ],
      address1
    );
    expect(result).toBeOk(Cl.uint(2));
  });
});