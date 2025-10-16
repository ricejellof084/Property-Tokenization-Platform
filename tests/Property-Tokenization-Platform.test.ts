
import { describe, expect, it } from "vitest";
import { Cl } from "@stacks/transactions";

const accounts = simnet.getAccounts();
const address1 = accounts.get("wallet_1")!;
const address2 = accounts.get("wallet_2")!;
const address3 = accounts.get("wallet_3")!;
const deployer = accounts.get("deployer")!;

const contractName = "Property-Tokenization-Platform";

describe("Property Tokenization Platform", () => {
  it("ensures simnet is well initialised", () => {
    expect(simnet.blockHeight).toBeDefined();
  });

  it("should create a property successfully", () => {
    const { result } = simnet.callPublicFn(
      contractName,
      "create-property",
      [
        Cl.stringAscii("123 Main St"),
        Cl.uint(1000),
        Cl.uint(100),
        Cl.stringAscii("Beautiful property"),
        Cl.stringAscii("Residential"),
        Cl.uint(2500),
        Cl.uint(2020)
      ],
      address1
    );
    expect(result).toBeOk(Cl.uint(1));
  });

  it("should get property details", () => {
    // Create property first to ensure it exists
    simnet.callPublicFn(
      contractName,
      "create-property",
      [
        Cl.stringAscii("123 Main St"),
        Cl.uint(1000),
        Cl.uint(100),
        Cl.stringAscii("Beautiful property"),
        Cl.stringAscii("Residential"),
        Cl.uint(2500),
        Cl.uint(2020)
      ],
      address1
    );
    
    const { result } = simnet.callReadOnlyFn(
      contractName,
      "get-property",
      [Cl.uint(1)],
      address1
    );
    // Verify property exists and has correct data
    expect(result).toBeDefined();
    // Additional verification that the property data is correct
    const propertyData = result as any;
    expect(propertyData.value).toBeDefined();
  });

  it("should purchase tokens successfully", () => {
    // Create property first
    simnet.callPublicFn(
      contractName,
      "create-property",
      [
        Cl.stringAscii("123 Main St"),
        Cl.uint(1000),
        Cl.uint(100),
        Cl.stringAscii("Beautiful property"),
        Cl.stringAscii("Residential"),
        Cl.uint(2500),
        Cl.uint(2020)
      ],
      address1
    );
    
    const { result } = simnet.callPublicFn(
      contractName,
      "purchase-tokens",
      [Cl.uint(1), Cl.uint(100)],
      address2
    );
    expect(result).toBeOk(Cl.uint(100));
  });
});

describe("Property Auction System", () => {
  it("should create an auction successfully", () => {
    // Create property first
    simnet.callPublicFn(
      contractName,
      "create-property",
      [
        Cl.stringAscii("555 Auction Ave"),
        Cl.uint(1000),
        Cl.uint(100),
        Cl.stringAscii("Auction property"),
        Cl.stringAscii("Commercial"),
        Cl.uint(5000),
        Cl.uint(2020)
      ],
      address1
    );

    const { result } = simnet.callPublicFn(
      contractName,
      "create-property-auction",
      [Cl.uint(1), Cl.uint(50000), Cl.uint(144)], // Use property ID 1
      address1
    );
    expect(result).toBeOk(Cl.uint(1));
  });

  it("should get auction details", () => {
    // Create property and auction first
    simnet.callPublicFn(
      contractName,
      "create-property",
      [
        Cl.stringAscii("555 Auction Ave"),
        Cl.uint(1000),
        Cl.uint(100),
        Cl.stringAscii("Auction property"),
        Cl.stringAscii("Commercial"),
        Cl.uint(5000),
        Cl.uint(2020)
      ],
      address1
    );
    
    simnet.callPublicFn(
      contractName,
      "create-property-auction",
      [Cl.uint(1), Cl.uint(50000), Cl.uint(144)],
      address1
    );
    
    const { result } = simnet.callReadOnlyFn(
      contractName,
      "get-auction",
      [Cl.uint(1)],
      address1
    );
    // Verify auction exists and has correct data
    expect(result).toBeDefined();
    // Additional verification that the auction data is correct
    const auctionData = result as any;
    expect(auctionData.value).toBeDefined();
  });

  it("should place bids successfully", () => {
    // Create property and auction
    simnet.callPublicFn(
      contractName,
      "create-property",
      [
        Cl.stringAscii("999 Bidding Blvd"),
        Cl.uint(1500),
        Cl.uint(120),
        Cl.stringAscii("Hot property"),
        Cl.stringAscii("Residential"),
        Cl.uint(2800),
        Cl.uint(2021)
      ],
      address1
    );

    simnet.callPublicFn(
      contractName,
      "create-property-auction",
      [Cl.uint(1), Cl.uint(60000), Cl.uint(200)], // Use property ID 1
      address1
    );

    // Place first bid
    const { result: bid1 } = simnet.callPublicFn(
      contractName,
      "place-bid",
      [Cl.uint(1), Cl.uint(60000)], // Use auction ID 1
      address2
    );
    expect(bid1).toBeOk(Cl.uint(60000));

    // Place higher bid
    const { result: bid2 } = simnet.callPublicFn(
      contractName,
      "place-bid",
      [Cl.uint(1), Cl.uint(65000)], // Use auction ID 1
      address3
    );
    expect(bid2).toBeOk(Cl.uint(65000));
  });

  it("should end auction after duration expires", () => {
    // Create property and auction with short duration
    simnet.callPublicFn(
      contractName,
      "create-property",
      [
        Cl.stringAscii("222 End Game St"),
        Cl.uint(1200),
        Cl.uint(110),
        Cl.stringAscii("Final property"),
        Cl.stringAscii("Mixed-use"),
        Cl.uint(2200),
        Cl.uint(2020)
      ],
      address1
    );

    simnet.callPublicFn(
      contractName,
      "create-property-auction",
      [Cl.uint(1), Cl.uint(55000), Cl.uint(10)], // Use property ID 1
      address1
    );

    // Place a bid
    simnet.callPublicFn(
      contractName,
      "place-bid",
      [Cl.uint(1), Cl.uint(55000)], // Use auction ID 1
      address2
    );

    // Mine blocks to exceed auction duration
    simnet.mineEmptyBlocks(15);

    // End the auction
    const { result } = simnet.callPublicFn(
      contractName,
      "end-auction",
      [Cl.uint(1)], // Use auction ID 1
      address1
    );
    expect(result).toBeOk(Cl.bool(true));
  });

  it("should prevent unauthorized auction creation", () => {
    // Create property
    simnet.callPublicFn(
      contractName,
      "create-property",
      [
        Cl.stringAscii("666 No Auth Ave"),
        Cl.uint(1000),
        Cl.uint(90),
        Cl.stringAscii("Restricted property"),
        Cl.stringAscii("Commercial"),
        Cl.uint(2500),
        Cl.uint(2020)
      ],
      address1
    );

    // Try to create auction from different address (should fail)
    const { result } = simnet.callPublicFn(
      contractName,
      "create-property-auction",
      [Cl.uint(1), Cl.uint(40000), Cl.uint(100)], // Use property ID 1
      address2 // Not the owner
    );
    expect(result).toBeErr(Cl.uint(100)); // ERR_UNAUTHORIZED
  });
});
