# Development Guidelines for Claude

## Core Philosophy

**TEST-DRIVEN DEVELOPMENT IS NON-NEGOTIABLE.** Every single line of production code must be written in response to a failing test. No exceptions. This is not a suggestion or a preference - it is the fundamental practice that enables all other principles in this document.

I follow Test-Driven Development (TDD) with a strong emphasis on behavior-driven testing, high-fidelity testing, and functional programming principles. All work should be done in small, incremental changes that maintain a working state throughout development.

## Quick Reference

**Key Principles:**

- Write tests first (TDD)
- Test behavior, not implementation
- Prefer higher fidelity tests: Real Implementations > Fakes > Mocks
- No `any` types or type assertions
- Immutable data only
- Small, pure functions
- TypeScript strict mode always
- Use real schemas/types in tests, never redefine them

**Preferred Tools:**

- **Language**: TypeScript (strict mode)
- **Testing**: Jest/Vitest + React Testing Library
- **Test Doubles**: Fakes over Mocks for higher fidelity
- **State Management**: Prefer immutable patterns


## Testing Principles

### High-Fidelity Testing Strategy

Following Google's testing best practices, we prioritize test fidelity to maximize confidence while maintaining fast execution:

**Test Double Hierarchy (in order of preference):**

1. **Real Implementations** (Highest Fidelity) - Use when lightweight and fast
2. **Fakes** (High Fidelity) - Lightweight implementations with realistic behavior
3. **Mocks** (Lowest Fidelity) - Only for verifying specific interactions

**Why Fakes Over Mocks:**

- **Realistic behavior**: Fakes implement actual logic, catching integration bugs mocks miss
- **State management**: Fakes maintain state between operations, testing realistic workflows
- **Better error detection**: Fakes can surface constraint violations and edge cases
- **Reduced brittleness**: Less coupled to implementation details than mocks


### Behavior-Driven Testing

- **No "unit tests"** - this term is not helpful. Tests should verify expected behavior, treating implementation as a black box
- Test through the public API exclusively - internals should be invisible to tests
- No 1:1 mapping between test files and implementation files
- Tests that examine internal implementation details are wasteful and should be avoided
- **Coverage targets**: 100% coverage should be expected at all times, but these tests must ALWAYS be based on business behaviour, not implementation details
- Tests must document expected business behaviour


### Testing Tools

- **Jest** or **Vitest** for testing frameworks
- **React Testing Library** for React components
- **Fake implementations** for external dependencies (databases, APIs, services)
- **MSW (Mock Service Worker)** for HTTP-level API testing when fakes aren't practical
- **Mocks only when**: Verifying specific interactions or when fakes are impractical
- All test code must follow the same TypeScript strict mode rules as production code


### Test Organization

```
src/
  features/
    payment/
      payment-processor.ts
      payment-validator.ts
      payment-processor.test.ts // The validator is an implementation detail. Validation is fully covered, but by testing the expected business behaviour, treating the validation code itself as an implementation detail
  __tests__/
    fakes/
      FakePaymentGateway.ts     // Fake implementations for external services
      FakeDatabase.ts           // Fake database with realistic constraints
      FakeEmailService.ts       // Fake email service with state tracking
```


### High-Fidelity Test Data Pattern

Use fake implementations with factory functions for realistic test scenarios:

```typescript
// __tests__/fakes/FakePaymentGateway.ts
interface Transaction {
  id: string;
  amount: number;
  currency: string;
  status: 'pending' | 'completed' | 'failed';
  createdAt: Date;
}

export class FakePaymentGateway {
  private transactions: Map<string, Transaction> = new Map();
  private nextId = 1;
  private shouldFailNext = false;
  private fraudDetectionEnabled = true;

  async processPayment(request: PaymentRequest): Promise<Transaction> {
    // Simulate realistic validation and business rules
    if (this.shouldFailNext) {
      this.shouldFailNext = false;
      throw new PaymentError('Gateway temporarily unavailable');
    }

    if (this.fraudDetectionEnabled && request.amount > 10000) {
      throw new PaymentError('Transaction flagged for fraud review');
    }

    // Simulate processing delay
    await new Promise(resolve => setTimeout(resolve, 10));

    const transaction: Transaction = {
      id: `txn_${this.nextId++}`,
      amount: request.amount,
      currency: request.currency,
      status: 'completed',
      createdAt: new Date()
    };

    this.transactions.set(transaction.id, transaction);
    return transaction;
  }

  async getTransaction(id: string): Promise<Transaction | null> {
    return this.transactions.get(id) || null;
  }

  // Test utilities
  simulateNextFailure() {
    this.shouldFailNext = true;
  }

  disableFraudDetection() {
    this.fraudDetectionEnabled = false;
  }

  getProcessedTransactions(): Transaction[] {
    return Array.from(this.transactions.values());
  }

  clear() {
    this.transactions.clear();
    this.nextId = 1;
    this.shouldFailNext = false;
    this.fraudDetectionEnabled = true;
  }
}

// Factory functions for complete test data
const getMockPaymentRequest = (
  overrides?: Partial<PaymentRequest>
): PaymentRequest => {
  return {
    amount: 100,
    currency: 'GBP',
    cardToken: 'tok_123456',
    customerId: 'cust_789',
    description: 'Test payment',
    ...overrides,
  };
};

// Usage in tests with high fidelity
describe('Payment processing', () => {
  let fakeGateway: FakePaymentGateway;
  let fakeDatabase: FakeDatabase;

  beforeEach(() => {
    fakeGateway = new FakePaymentGateway();
    fakeDatabase = new FakeDatabase();
  });

  afterEach(() => {
    fakeGateway.clear();
    fakeDatabase.clear();
  });

  it('should process payment and store transaction record', async () => {
    const paymentRequest = getMockPaymentRequest({ amount: 150 });
    
    const result = await processPayment(paymentRequest, {
      gateway: fakeGateway,
      database: fakeDatabase
    });

    expect(result.success).toBe(true);
    
    // Verify realistic end-to-end behavior
    const storedPayment = await fakeDatabase.getPaymentById(result.data.id);
    expect(storedPayment?.amount).toBe(150);
    expect(storedPayment?.status).toBe('completed');
    
    const gatewayTransactions = fakeGateway.getProcessedTransactions();
    expect(gatewayTransactions).toHaveLength(1);
    expect(gatewayTransactions[^0].amount).toBe(150);
  });

  it('should handle gateway failures gracefully', async () => {
    fakeGateway.simulateNextFailure();
    const paymentRequest = getMockPaymentRequest();
    
    const result = await processPayment(paymentRequest, {
      gateway: fakeGateway,
      database: fakeDatabase
    });

    expect(result.success).toBe(false);
    expect(result.error.message).toBe('Gateway temporarily unavailable');
    
    // Verify no partial state was left behind
    const storedPayments = await fakeDatabase.getAllPayments();
    expect(storedPayments).toHaveLength(0);
  });
});
```

Key principles for high-fidelity test data:

- **Realistic constraints**: Fakes should implement business rules and validation
- **State management**: Maintain state between operations for realistic workflows
- **Error simulation**: Provide ways to simulate realistic failure scenarios
- **Complete objects**: Factory functions return fully populated, valid objects
- **Optional overrides**: Allow selective customization of test data
- **Composable**: Build complex scenarios by combining simple fakes


## TypeScript Guidelines

### Strict Mode Requirements

```json
// tsconfig.json
{
  "compilerOptions": {
    "strict": true,
    "noImplicitAny": true,
    "strictNullChecks": true,
    "strictFunctionTypes": true,
    "strictBindCallApply": true,
    "strictPropertyInitialization": true,
    "noImplicitThis": true,
    "alwaysStrict": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "noImplicitReturns": true,
    "noFallthroughCasesInSwitch": true
  }
}
```

- **No `any`** - ever. Use `unknown` if type is truly unknown
- **No type assertions** (`as SomeType`) unless absolutely necessary with clear justification
- **No `@ts-ignore`** or `@ts-expect-error` without explicit explanation
- These rules apply to test code as well as production code


### Type Definitions

- **Prefer `type` over `interface`** in all cases
- Use explicit typing where it aids clarity, but leverage inference where appropriate
- Utilize utility types effectively (`Pick`, `Omit`, `Partial`, `Required`, etc.)
- Create domain-specific types (e.g., `UserId`, `PaymentId`) for type safety
- Use Zod or any other [Standard Schema](https://standardschema.dev/) compliant schema library to create types, by creating schemas first

```typescript
// Good
type UserId = string & { readonly brand: unique symbol };
type PaymentAmount = number & { readonly brand: unique symbol };

// Avoid
type UserId = string;
type PaymentAmount = number;
```


#### Schema-First Development with Zod

Always define your schemas first, then derive types from them:

```typescript
import { z } from "zod";

// Define schemas first - these provide runtime validation
const AddressDetailsSchema = z.object({
  houseNumber: z.string(),
  houseName: z.string().optional(),
  addressLine1: z.string().min(1),
  addressLine2: z.string().optional(),
  city: z.string().min(1),
  postcode: z.string().regex(/^[A-Z]{1,2}\d[A-Z\d]? ?\d[A-Z]{2}$/i),
});

const PayingCardDetailsSchema = z.object({
  cvv: z.string().regex(/^\d{3,4}$/),
  token: z.string().min(1),
});

const PostPaymentsRequestV3Schema = z.object({
  cardAccountId: z.string().length(16),
  amount: z.number().positive(),
  source: z.enum(["Web", "Mobile", "API"]),
  accountStatus: z.enum(["Normal", "Restricted", "Closed"]),
  lastName: z.string().min(1),
  dateOfBirth: z.string().regex(/^\d{4}-\d{2}-\d{2}$/),
  payingCardDetails: PayingCardDetailsSchema,
  addressDetails: AddressDetailsSchema,
  brand: z.enum(["Visa", "Mastercard", "Amex"]),
});

// Derive types from schemas
type AddressDetails = z.infer<typeof AddressDetailsSchema>;
type PayingCardDetails = z.infer<typeof PayingCardDetailsSchema>;
type PostPaymentsRequestV3 = z.infer<typeof PostPaymentsRequestV3Schema>;

// Use schemas at runtime boundaries
export const parsePaymentRequest = (data: unknown): PostPaymentsRequestV3 => {
  return PostPaymentsRequestV3Schema.parse(data);
};
```


#### Schema Usage in Tests and Fakes

**CRITICAL**: Tests and fakes must use real schemas and types from the main project, not redefine their own.

```typescript
// ❌ WRONG - Defining schemas in test files or fakes
const ProjectSchema = z.object({
  id: z.string(),
  workspaceId: z.string(),
  ownerId: z.string().nullable(),
  name: z.string(),
  createdAt: z.coerce.date(),
  updatedAt: z.coerce.date(),
});

// ✅ CORRECT - Import schemas from the shared schema package
import { ProjectSchema, type Project } from "@your-org/schemas";

// ✅ CORRECT - Fakes using real schemas for validation
export class FakeProjectDatabase {
  private projects: Map<string, Project> = new Map();

  async createProject(data: Omit<Project, 'id' | 'createdAt' | 'updatedAt'>): Promise<Project> {
    const project: Project = {
      ...data,
      id: `proj_${Date.now()}`,
      createdAt: new Date(),
      updatedAt: new Date(),
    };

    // Validate against real schema to catch type mismatches
    const validatedProject = ProjectSchema.parse(project);
    this.projects.set(validatedProject.id, validatedProject);
    
    return validatedProject;
  }
}
```


## Code Style

### Functional Programming

I follow a "functional light" approach:

- **No data mutation** - work with immutable data structures
- **Pure functions** wherever possible
- **Composition** as the primary mechanism for code reuse
- Avoid heavy FP abstractions (no need for complex monads or pipe/compose patterns) unless there is a clear advantage to using them
- Use array methods (`map`, `filter`, `reduce`) over imperative loops


#### Examples of Functional Patterns

```typescript
// Good - Pure function with immutable updates
const applyDiscount = (order: Order, discountPercent: number): Order => {
  return {
    ...order,
    items: order.items.map((item) => ({
      ...item,
      price: item.price * (1 - discountPercent / 100),
    })),
    totalPrice: order.items.reduce(
      (sum, item) => sum + item.price * (1 - discountPercent / 100),
      0
    ),
  };
};

// Good - Composition over complex logic
const processOrder = (order: Order): ProcessedOrder => {
  return pipe(
    order,
    validateOrder,
    applyPromotions,
    calculateTax,
    assignWarehouse
  );
};

// When heavy FP abstractions ARE appropriate:
// - Complex async flows that benefit from Task/IO types
// - Error handling chains that benefit from Result/Either types
// Example with Result type for complex error handling:
type Result<T, E = Error> =
  | { success: true; data: T }
  | { success: false; error: E };

const chainPaymentOperations = (
  payment: Payment
): Result<Receipt, PaymentError> => {
  return pipe(
    validatePayment(payment),
    chain(authorizePayment),
    chain(capturePayment),
    map(generateReceipt)
  );
};
```


### Code Structure

- **No nested if/else statements** - use early returns, guard clauses, or composition
- **Avoid deep nesting** in general (max 2 levels)
- Keep functions small and focused on a single responsibility
- Prefer flat, readable code over clever abstractions


### Naming Conventions

- **Functions**: `camelCase`, verb-based (e.g., `calculateTotal`, `validatePayment`)
- **Types**: `PascalCase` (e.g., `PaymentRequest`, `UserProfile`)
- **Constants**: `UPPER_SNAKE_CASE` for true constants, `camelCase` for configuration
- **Files**: `kebab-case.ts` for all TypeScript files
- **Test files**: `*.test.ts` or `*.spec.ts`
- **Fake files**: `Fake*.ts` (e.g., `FakePaymentGateway.ts`, `FakeDatabase.ts`)


### No Comments in Code

Code should be self-documenting through clear naming and structure. Comments indicate that the code itself is not clear enough.

```typescript
// Avoid: Comments explaining what the code does
const calculateDiscount = (price: number, customer: Customer): number => {
  // Check if customer is premium
  if (customer.tier === "premium") {
    // Apply 20% discount for premium customers
    return price * 0.8;
  }
  // Regular customers get 10% discount
  return price * 0.9;
};

// Good: Self-documenting code with clear names
const PREMIUM_DISCOUNT_MULTIPLIER = 0.8;
const STANDARD_DISCOUNT_MULTIPLIER = 0.9;

const isPremiumCustomer = (customer: Customer): boolean => {
  return customer.tier === "premium";
};

const calculateDiscount = (price: number, customer: Customer): number => {
  const discountMultiplier = isPremiumCustomer(customer)
    ? PREMIUM_DISCOUNT_MULTIPLIER
    : STANDARD_DISCOUNT_MULTIPLIER;

  return price * discountMultiplier;
};

// Avoid: Complex logic with comments
const processPayment = (payment: Payment): ProcessedPayment => {
  // First validate the payment
  if (!validatePayment(payment)) {
    throw new Error("Invalid payment");
  }

  // Check if we need to apply 3D secure
  if (payment.amount > 100 && payment.card.type === "credit") {
    // Apply 3D secure for credit cards over £100
    const securePayment = apply3DSecure(payment);
    // Process the secure payment
    return executePayment(securePayment);
  }

  // Process the payment
  return executePayment(payment);
};

// Good: Extract to well-named functions
const requires3DSecure = (payment: Payment): boolean => {
  const SECURE_PAYMENT_THRESHOLD = 100;
  return (
    payment.amount > SECURE_PAYMENT_THRESHOLD && payment.card.type === "credit"
  );
};

const processPayment = (payment: Payment): ProcessedPayment => {
  if (!validatePayment(payment)) {
    throw new PaymentValidationError("Invalid payment");
  }

  const securedPayment = requires3DSecure(payment)
    ? apply3DSecure(payment)
    : payment;

  return executePayment(securedPayment);
};
```

**Exception**: JSDoc comments for public APIs are acceptable when generating documentation, but the code should still be self-explanatory without them.

### Prefer Options Objects

Use options objects for function parameters as the default pattern. Only use positional parameters when there's a clear, compelling reason (e.g., single-parameter pure functions, well-established conventions like `map(item => item.value)`).

```typescript
// Avoid: Multiple positional parameters
const createPayment = (
  amount: number,
  currency: string,
  cardId: string,
  customerId: string,
  description?: string,
  metadata?: Record<string, unknown>,
  idempotencyKey?: string
): Payment => {
  // implementation
};

// Calling it is unclear
const payment = createPayment(
  100,
  "GBP",
  "card_123",
  "cust_456",
  undefined,
  { orderId: "order_789" },
  "key_123"
);

// Good: Options object with clear property names
type CreatePaymentOptions = {
  amount: number;
  currency: string;
  cardId: string;
  customerId: string;
  description?: string;
  metadata?: Record<string, unknown>;
  idempotencyKey?: string;
};

const createPayment = (options: CreatePaymentOptions): Payment => {
  const {
    amount,
    currency,
    cardId,
    customerId,
    description,
    metadata,
    idempotencyKey,
  } = options;

  // implementation
};

// Clear and readable at call site
const payment = createPayment({
  amount: 100,
  currency: "GBP",
  cardId: "card_123",
  customerId: "cust_456",
  metadata: { orderId: "order_789" },
  idempotencyKey: "key_123",
});

// Avoid: Boolean flags as parameters
const fetchCustomers = (
  includeInactive: boolean,
  includePending: boolean,
  includeDeleted: boolean,
  sortByDate: boolean
): Customer[] => {
  // implementation
};

// Confusing at call site
const customers = fetchCustomers(true, false, false, true);

// Good: Options object with clear intent
type FetchCustomersOptions = {
  includeInactive?: boolean;
  includePending?: boolean;
  includeDeleted?: boolean;
  sortBy?: "date" | "name" | "value";
};

const fetchCustomers = (options: FetchCustomersOptions = {}): Customer[] => {
  const {
    includeInactive = false,
    includePending = false,
    includeDeleted = false,
    sortBy = "name",
  } = options;

  // implementation
};

// Self-documenting at call site
const customers = fetchCustomers({
  includeInactive: true,
  sortBy: "date",
});

// Good: Configuration objects for complex operations
type ProcessOrderOptions = {
  order: Order;
  shipping: {
    method: "standard" | "express" | "overnight";
    address: Address;
  };
  payment: {
    method: PaymentMethod;
    saveForFuture?: boolean;
  };
  promotions?: {
    codes?: string[];
    autoApply?: boolean;
  };
};

const processOrder = (options: ProcessOrderOptions): ProcessedOrder => {
  const { order, shipping, payment, promotions = {} } = options;

  // Clear access to nested options
  const orderWithPromotions = promotions.autoApply
    ? applyAvailablePromotions(order)
    : order;

  return executeOrder({
    ...orderWithPromotions,
    shippingMethod: shipping.method,
    paymentMethod: payment.method,
  });
};

// Acceptable: Single parameter for simple transforms
const double = (n: number): number => n * 2;
const getName = (user: User): string => user.name;

// Acceptable: Well-established patterns
const numbers = [1, 2, 3];
const doubled = numbers.map((n) => n * 2);
const users = fetchUsers();
const names = users.map((user) => user.name);
```

**Guidelines for options objects:**

- Default to options objects unless there's a specific reason not to
- Always use for functions with optional parameters
- Destructure options at the start of the function for clarity
- Provide sensible defaults using destructuring
- Keep related options grouped (e.g., all shipping options together)
- Consider breaking very large options objects into nested groups

**When positional parameters are acceptable:**

- Single-parameter pure functions
- Well-established functional patterns (map, filter, reduce callbacks)
- Mathematical operations where order is conventional

## Development Workflow

### TDD Process - THE FUNDAMENTAL PRACTICE

**CRITICAL**: TDD is not optional. Every feature, every bug fix, every change MUST follow this process:

Follow Red-Green-Refactor strictly:

1. **Red**: Write a failing test for the desired behavior. NO PRODUCTION CODE until you have a failing test.
2. **Green**: Write the MINIMUM code to make the test pass. Resist the urge to write more than needed.
3. **Refactor**: Assess the code for improvement opportunities. If refactoring would add value, clean up the code while keeping tests green. If the code is already clean and expressive, move on.

**Common TDD Violations to Avoid:**

- Writing production code without a failing test first
- Writing multiple tests before making the first one pass
- Writing more production code than needed to pass the current test
- Skipping the refactor assessment step when code could be improved
- Adding functionality "while you're there" without a test driving it

**Remember**: If you're typing production code and there isn't a failing test demanding that code, you're not doing TDD.

#### TDD Example Workflow

```typescript
// Step 1: Red - Start with the simplest behavior
describe("Order processing", () => {
  let fakeShippingService: FakeShippingService;

  beforeEach(() => {
    fakeShippingService = new FakeShippingService();
  });

  it("should calculate total with shipping cost", () => {
    const order = createOrder({
      items: [{ price: 30, quantity: 1 }],
      shippingCost: 5.99,
    });

    const processed = processOrder(order, {
      shippingService: fakeShippingService
    });

    expect(processed.total).toBe(35.99);
    expect(processed.shippingCost).toBe(5.99);
  });
});

// Step 2: Green - Minimal implementation
interface OrderServices {
  shippingService: ShippingService;
}

const processOrder = (order: Order, services: OrderServices): ProcessedOrder => {
  const itemsTotal = order.items.reduce(
    (sum, item) => sum + item.price * item.quantity,
    0
  );

  return {
    ...order,
    shippingCost: order.shippingCost,
    total: itemsTotal + order.shippingCost,
  };
};

// Step 3: Red - Add test for free shipping behavior
describe("Order processing", () => {
  it("should calculate total with shipping cost", () => {
    // ... existing test
  });

  it("should apply free shipping for orders over £50", () => {
    const order = createOrder({
      items: [{ price: 60, quantity: 1 }],
      shippingCost: 5.99,
    });
    
    fakeShippingService.setFreeShippingThreshold(50);

    const processed = processOrder(order, {
      shippingService: fakeShippingService
    });

    expect(processed.shippingCost).toBe(0);
    expect(processed.total).toBe(60);
  });
});

// Step 4: Green - NOW we can add the conditional because both paths are tested
const processOrder = (order: Order, services: OrderServices): ProcessedOrder => {
  const itemsTotal = order.items.reduce(
    (sum, item) => sum + item.price * item.quantity,
    0
  );

  const shippingCost = services.shippingService.calculateShipping(
    itemsTotal,
    order.shippingCost
  );

  return {
    ...order,
    shippingCost,
    total: itemsTotal + shippingCost,
  };
};

// Step 5: Add edge case tests to ensure 100% behavior coverage
describe("Order processing", () => {
  // ... existing tests

  it("should charge shipping for orders exactly at £50", () => {
    const order = createOrder({
      items: [{ price: 50, quantity: 1 }],
      shippingCost: 5.99,
    });
    
    fakeShippingService.setFreeShippingThreshold(50);

    const processed = processOrder(order, {
      shippingService: fakeShippingService
    });

    expect(processed.shippingCost).toBe(5.99);
    expect(processed.total).toBe(55.99);
  });
});

// Step 6: Refactor - Extract constants and improve readability
const FREE_SHIPPING_THRESHOLD = 50;

const calculateItemsTotal = (items: OrderItem[]): number => {
  return items.reduce((sum, item) => sum + item.price * item.quantity, 0);
};

const processOrder = (order: Order, services: OrderServices): ProcessedOrder => {
  const itemsTotal = calculateItemsTotal(order.items);
  const shippingCost = services.shippingService.calculateShipping(
    itemsTotal,
    order.shippingCost
  );

  return {
    ...order,
    shippingCost,
    total: itemsTotal + shippingCost,
  };
};
```


### When to Use Each Testing Approach

**Use Real Implementations When:**

- Dependencies are lightweight (pure functions, simple calculations)
- No external side effects (network calls, file system, databases)
- Fast execution doesn't impact test performance

**Use Fakes When:**

- Need realistic behavior with constraints and state
- Testing complex workflows and integrations
- Want to catch business logic bugs and edge cases
- Dependencies have side effects but you want high fidelity

**Use Mocks When:**

- Only need to verify specific method calls occurred
- Dependency behavior isn't relevant to the test
- Testing error handling where interaction matters more than response logic
- Dependency is too complex to fake effectively

```typescript
// ✅ Good: Use real implementation for pure functions
const calculateDiscount = (price: number, tier: CustomerTier): number => {
  // Pure function - use directly in tests
};

// ✅ Good: Use fake for stateful dependencies
class FakeInventoryService {
  private stock: Map<string, number> = new Map();
  
  checkAvailability(productId: string, quantity: number): boolean {
    return (this.stock.get(productId) || 0) >= quantity;
  }
  
  reserveItems(productId: string, quantity: number): void {
    const current = this.stock.get(productId) || 0;
    this.stock.set(productId, current - quantity);
  }
}

// ✅ Good: Use mock when only interaction matters
it('should log audit event when payment processed', async () => {
  const mockAuditLogger = jest.fn();
  
  await processPayment(payment, { auditLogger: mockAuditLogger });
  
  expect(mockAuditLogger).toHaveBeenCalledWith({
    event: 'payment_processed',
    paymentId: payment.id,
    amount: payment.amount
  });
});
```


### Refactoring - The Critical Third Step

Evaluating refactoring opportunities is not optional - it's the third step in the TDD cycle. After achieving a green state and committing your work, you MUST assess whether the code can be improved. However, only refactor if there's clear value - if the code is already clean and expresses intent well, move on to the next test.

#### What is Refactoring?

Refactoring means changing the internal structure of code without changing its external behavior. The public API remains unchanged, all tests continue to pass, but the code becomes cleaner, more maintainable, or more efficient. Remember: only refactor when it genuinely improves the code - not all code needs refactoring.

#### When to Refactor

- **Always assess after green**: Once tests pass, before moving to the next test, evaluate if refactoring would add value
- **When you see duplication**: But understand what duplication really means (see DRY below)
- **When names could be clearer**: Variable names, function names, or type names that don't clearly express intent
- **When structure could be simpler**: Complex conditional logic, deeply nested code, or long functions
- **When patterns emerge**: After implementing several similar features, useful abstractions may become apparent

**Remember**: Not all code needs refactoring. If the code is already clean, expressive, and well-structured, commit and move on. Refactoring should improve the code - don't change things just for the sake of change.

#### Refactoring Guidelines

##### 1. Commit Before Refactoring

Always commit your working code before starting any refactoring. This gives you a safe point to return to:

```bash
git add .
git commit -m "feat: add payment validation"
# Now safe to refactor
```


##### 2. Look for Useful Abstractions Based on Semantic Meaning

Create abstractions only when code shares the same semantic meaning and purpose. Don't abstract based on structural similarity alone - **duplicate code is far cheaper than the wrong abstraction**.

```typescript
// Similar structure, DIFFERENT semantic meaning - DO NOT ABSTRACT
const validatePaymentAmount = (amount: number): boolean => {
  return amount > 0 && amount <= 10000;
};

const validateTransferAmount = (amount: number): boolean => {
  return amount > 0 && amount <= 10000;
};

// These might have the same structure today, but they represent different
// business concepts that will likely evolve independently.
// Payment limits might change based on fraud rules.
// Transfer limits might change based on account type.
// Abstracting them couples unrelated business rules.

// Similar structure, SAME semantic meaning - SAFE TO ABSTRACT
const formatUserDisplayName = (firstName: string, lastName: string): string => {
  return `${firstName} ${lastName}`.trim();
};

const formatCustomerDisplayName = (
  firstName: string,
  lastName: string
): string => {
  return `${firstName} ${lastName}`.trim();
};

const formatEmployeeDisplayName = (
  firstName: string,
  lastName: string
): string => {
  return `${firstName} ${lastName}`.trim();
};

// These all represent the same concept: "how we format a person's name for display"
// They share semantic meaning, not just structure
const formatPersonDisplayName = (
  firstName: string,
  lastName: string
): string => {
  return `${firstName} ${lastName}`.trim();
};
```

**Questions to ask before abstracting:**

- Do these code blocks represent the same concept or different concepts that happen to look similar?
- If the business rules for one change, should the others change too?
- Would a developer reading this abstraction understand why these things are grouped together?
- Am I abstracting based on what the code IS (structure) or what it MEANS (semantics)?

**Remember**: It's much easier to create an abstraction later when the semantic relationship becomes clear than to undo a bad abstraction that couples unrelated concepts.

##### 3. Understanding DRY - It's About Knowledge, Not Code

DRY (Don't Repeat Yourself) is about not duplicating **knowledge** in the system, not about eliminating all code that looks similar.

```typescript
// This is NOT a DRY violation - different knowledge despite similar code
const validateUserAge = (age: number): boolean => {
  return age >= 18 && age <= 100;
};

const validateProductRating = (rating: number): boolean => {
  return rating >= 1 && rating <= 5;
};

const validateYearsOfExperience = (years: number): boolean => {
  return years >= 0 && years <= 50;
};

// These functions have similar structure (checking numeric ranges), but they
// represent completely different business rules:
// - User age has legal requirements (18+) and practical limits (100)
// - Product ratings follow a 1-5 star system
// - Years of experience starts at 0 with a reasonable upper bound
// Abstracting them would couple unrelated business concepts and make future
// changes harder. What if ratings change to 1-10? What if legal age changes?
```


##### 4. Maintain External APIs During Refactoring

Refactoring must never break existing consumers of your code:

```typescript
// Original implementation
export const processPayment = (payment: Payment): ProcessedPayment => {
  // Complex logic all in one function
  if (payment.amount <= 0) {
    throw new Error("Invalid amount");
  }

  if (payment.amount > 10000) {
    throw new Error("Amount too large");
  }

  // ... 50 more lines of validation and processing

  return result;
};

// Refactored - external API unchanged, internals improved
export const processPayment = (payment: Payment): ProcessedPayment => {
  validatePaymentAmount(payment.amount);
  validatePaymentMethod(payment.method);

  const authorizedPayment = authorizePayment(payment);
  const capturedPayment = capturePayment(authorizedPayment);

  return generateReceipt(capturedPayment);
};

// New internal functions - not exported
const validatePaymentAmount = (amount: number): void => {
  if (amount <= 0) {
    throw new Error("Invalid amount");
  }

  if (amount > 10000) {
    throw new Error("Amount too large");
  }
};

// Tests continue to pass without modification because external API unchanged
```


##### 5. Verify and Commit After Refactoring

**CRITICAL**: After every refactoring:

1. Run all tests - they must pass without modification
2. Run static analysis (linting, type checking) - must pass
3. Commit the refactoring separately from feature changes
```bash
# After refactoring
npm test          # All tests must pass
npm run lint      # All linting must pass
npm run typecheck # TypeScript must be happy

# Only then commit
git add .
git commit -m "refactor: extract payment validation helpers"
```


### Commit Guidelines

- Each commit should represent a complete, working change
- Use conventional commits format:

```
feat: add payment validation
fix: correct date formatting in payment processor
refactor: extract payment validation logic
test: add edge cases for payment validation
```

- Include test changes with feature changes in the same commit


### Pull Request Standards

- Every PR must have all tests passing
- All linting and quality checks must pass
- Work in small increments that maintain a working state
- PRs should be focused on a single feature or fix
- Include description of the behavior change, not implementation details


## Working with Claude

### Expectations

When working with my code:

1. **ALWAYS FOLLOW TDD** - No production code without a failing test. This is not negotiable.
2. **Prioritize high-fidelity testing** - Prefer fakes over mocks for better test confidence
3. **Think deeply** before making any edits
4. **Understand the full context** of the code and requirements
5. **Ask clarifying questions** when requirements are ambiguous
6. **Think from first principles** - don't make assumptions
7. **Assess refactoring after every green** - Look for opportunities to improve code structure, but only refactor if it adds value
8. **Keep project docs current** - update them whenever you introduce meaningful changes

### Code Changes

When suggesting or making changes:

- **Start with a failing test** - always. No exceptions.
- Use fakes for external dependencies where practical for higher fidelity
- After making tests pass, always assess refactoring opportunities (but only refactor if it adds value)
- After refactoring, verify all tests and static analysis pass, then commit
- Respect the existing patterns and conventions
- Maintain test coverage for all behavior changes
- Keep changes small and incremental
- Ensure all TypeScript strict mode requirements are met
- Provide rationale for significant design decisions

**If you find yourself writing production code without a failing test, STOP immediately and write the test first.**

### Communication

- Be explicit about trade-offs in different approaches
- Explain the reasoning behind significant design decisions
- Flag any deviations from these guidelines with justification
- Suggest improvements that align with these principles
- When unsure, ask for clarification rather than assuming


## Example Patterns

### Error Handling

Use Result types or early returns:

```typescript
// Good - Result type pattern
type Result<T, E = Error> =
  | { success: true; data: T }
  | { success: false; error: E };

const processPayment = (
  payment: Payment
): Result<ProcessedPayment, PaymentError> => {
  if (!isValidPayment(payment)) {
    return { success: false, error: new PaymentError("Invalid payment") };
  }

  if (!hasSufficientFunds(payment)) {
    return { success: false, error: new PaymentError("Insufficient funds") };
  }

  return { success: true, data: executePayment(payment) };
};

// Also good - early returns with exceptions
const processPayment = (payment: Payment): ProcessedPayment => {
  if (!isValidPayment(payment)) {
    throw new PaymentError("Invalid payment");
  }

  if (!hasSufficientFunds(payment)) {
    throw new PaymentError("Insufficient funds");
  }

  return executePayment(payment);
};
```


### Testing Behavior

```typescript
// Good - tests behavior through fakes that simulate real constraints
describe("PaymentProcessor", () => {
  let fakePaymentGateway: FakePaymentGateway;
  let fakeAccountService: FakeAccountService;

  beforeEach(() => {
    fakePaymentGateway = new FakePaymentGateway();
    fakeAccountService = new FakeAccountService();
  });

  afterEach(() => {
    fakePaymentGateway.clear();
    fakeAccountService.clear();
  });

  it("should decline payment when insufficient funds", async () => {
    const account = fakeAccountService.createAccount({ balance: 500 });
    const payment = getMockPaymentRequest({ amount: 1000, accountId: account.id });

    const result = await processPayment(payment, {
      gateway: fakePaymentGateway,
      accountService: fakeAccountService
    });

    expect(result.success).toBe(false);
    expect(result.error.message).toBe("Insufficient funds");
    
    // Verify realistic state - account balance unchanged
    const updatedAccount = await fakeAccountService.getAccount(account.id);
    expect(updatedAccount.balance).toBe(500);
    
    // Verify no transaction was recorded
    const transactions = fakePaymentGateway.getProcessedTransactions();
    expect(transactions).toHaveLength(0);
  });

  it("should process valid payment and update account balance", async () => {
    const account = fakeAccountService.createAccount({ balance: 1000 });
    const payment = getMockPaymentRequest({ amount: 300, accountId: account.id });

    const result = await processPayment(payment, {
      gateway: fakePaymentGateway,
      accountService: fakeAccountService
    });

    expect(result.success).toBe(true);
    expect(result.data.status).toBe('completed');
    
    // Verify realistic end-to-end behavior
    const updatedAccount = await fakeAccountService.getAccount(account.id);
    expect(updatedAccount.balance).toBe(700);
    
    const transactions = fakePaymentGateway.getProcessedTransactions();
    expect(transactions).toHaveLength(1);
    expect(transactions[^0].amount).toBe(300);
  });

  it("should handle concurrent payment attempts correctly", async () => {
    const account = fakeAccountService.createAccount({ balance: 1000 });
    const payment1 = getMockPaymentRequest({ amount: 600, accountId: account.id });
    const payment2 = getMockPaymentRequest({ amount: 600, accountId: account.id });

    // Process payments concurrently
    const [result1, result2] = await Promise.all([
      processPayment(payment1, { gateway: fakePaymentGateway, accountService: fakeAccountService }),
      processPayment(payment2, { gateway: fakePaymentGateway, accountService: fakeAccountService })
    ]);

    // One should succeed, one should fail due to insufficient funds
    const results = [result1, result2];
    const successCount = results.filter(r => r.success).length;
    const failureCount = results.filter(r => !r.success).length;
    
    expect(successCount).toBe(1);
    expect(failureCount).toBe(1);
    
    // Account should have exactly one payment deducted
    const finalAccount = await fakeAccountService.getAccount(account.id);
    expect(finalAccount.balance).toBe(400);
  });
});

// Avoid - testing implementation details
describe("PaymentProcessor", () => {
  it("should call checkBalance method", () => {
    // This tests implementation, not behavior
    const mockAccountService = { checkBalance: jest.fn().mockReturnValue(true) };
    // ... test that verifies method was called but not realistic behavior
  });
});
```


#### Achieving 100% Coverage Through Business Behavior

Example showing how validation code gets 100% coverage without testing it directly:

```typescript
// payment-validator.ts (implementation detail)
export const validatePaymentAmount = (amount: number): boolean => {
  return amount > 0 && amount <= 10000;
};

export const validateCardDetails = (card: PayingCardDetails): boolean => {
  return /^\d{3,4}$/.test(card.cvv) && card.token.length > 0;
};

// payment-processor.ts (public API)
export const processPayment = (
  request: PaymentRequest,
  services: PaymentServices
): Promise<Result<Payment, PaymentError>> => {
  // Validation is used internally but not exposed
  if (!validatePaymentAmount(request.amount)) {
    return Promise.resolve({ 
      success: false, 
      error: new PaymentError("Invalid amount") 
    });
  }

  if (!validateCardDetails(request.payingCardDetails)) {
    return Promise.resolve({ 
      success: false, 
      error: new PaymentError("Invalid card details") 
    });
  }

  // Process payment using services...
  return services.gateway.processPayment(request);
};

// payment-processor.test.ts
describe("Payment processing", () => {
  let fakeGateway: FakePaymentGateway;

  beforeEach(() => {
    fakeGateway = new FakePaymentGateway();
  });

  // These tests achieve 100% coverage of validation code
  // without directly testing the validator functions

  it("should reject payments with negative amounts", async () => {
    const payment = getMockPaymentRequest({ amount: -100 });
    const result = await processPayment(payment, { gateway: fakeGateway });

    expect(result.success).toBe(false);
    expect(result.error.message).toBe("Invalid amount");
    
    // Verify no payment was attempted at gateway level
    expect(fakeGateway.getProcessedTransactions()).toHaveLength(0);
  });

  it("should reject payments exceeding maximum amount", async () => {
    const payment = getMockPaymentRequest({ amount: 10001 });
    const result = await processPayment(payment, { gateway: fakeGateway });

    expect(result.success).toBe(false);
    expect(result.error.message).toBe("Invalid amount");
    
    expect(fakeGateway.getProcessedTransactions()).toHaveLength(0);
  });

  it("should reject payments with invalid CVV format", async () => {
    const payment = getMockPaymentRequest({
      payingCardDetails: { cvv: "12", token: "valid-token" },
    });
    const result = await processPayment(payment, { gateway: fakeGateway });

    expect(result.success).toBe(false);
    expect(result.error.message).toBe("Invalid card details");
    
    expect(fakeGateway.getProcessedTransactions()).toHaveLength(0);
  });

  it("should process valid payments successfully", async () => {
    const payment = getMockPaymentRequest({
      amount: 100,
      payingCardDetails: { cvv: "123", token: "valid-token" },
    });
    const result = await processPayment(payment, { gateway: fakeGateway });

    expect(result.success).toBe(true);
    expect(result.data.status).toBe("completed");
    
    const transactions = fakeGateway.getProcessedTransactions();
    expect(transactions).toHaveLength(1);
    expect(transactions[^0].amount).toBe(100);
  });
});
```


### React Component Testing

```typescript
// Good - testing user-visible behavior with realistic services
describe("PaymentForm", () => {
  let fakePaymentService: FakePaymentService;

  beforeEach(() => {
    fakePaymentService = new FakePaymentService();
  });

  it("should show error when submitting invalid amount", async () => {
    render(<PaymentForm paymentService={fakePaymentService} />);

    const amountInput = screen.getByLabelText("Amount");
    const submitButton = screen.getByRole("button", { name: "Submit Payment" });

    await userEvent.type(amountInput, "-100");
    await userEvent.click(submitButton);

    expect(screen.getByText("Amount must be positive")).toBeInTheDocument();
    
    // Verify no payment was processed
    expect(fakePaymentService.getProcessedPayments()).toHaveLength(0);
  });

  it("should handle payment service failures gracefully", async () => {
    fakePaymentService.simulateNextFailure();
    
    render(<PaymentForm paymentService={fakePaymentService} />);

    const amountInput = screen.getByLabelText("Amount");
    const submitButton = screen.getByRole("button", { name: "Submit Payment" });

    await userEvent.type(amountInput, "100");
    await userEvent.click(submitButton);

    await waitFor(() => {
      expect(screen.getByText("Payment failed. Please try again.")).toBeInTheDocument();
    });
    
    // Verify failure was attempted but not recorded as successful
    expect(fakePaymentService.getProcessedPayments()).toHaveLength(0);
    expect(fakePaymentService.getFailedAttempts()).toHaveLength(1);
  });
});
```


## Common Patterns to Avoid

### Anti-patterns

```typescript
// Avoid: Mutation
const addItem = (items: Item[], newItem: Item) => {
  items.push(newItem); // Mutates array
  return items;
};

// Prefer: Immutable update
const addItem = (items: Item[], newItem: Item): Item[] => {
  return [...items, newItem];
};

// Avoid: Nested conditionals
if (user) {
  if (user.isActive) {
    if (user.hasPermission) {
      // do something
    }
  }
}

// Prefer: Early returns
if (!user || !user.isActive || !user.hasPermission) {
  return;
}
// do something

// Avoid: Large functions
const processOrder = (order: Order) => {
  // 100+ lines of code
};

// Prefer: Composed small functions
const processOrder = (order: Order) => {
  const validatedOrder = validateOrder(order);
  const pricedOrder = calculatePricing(validatedOrder);
  const finalOrder = applyDiscounts(pricedOrder);
  return submitOrder(finalOrder);
};

// Avoid: Over-mocking with implementation details
it('should call specific internal methods', () => {
  const mockValidator = jest.fn();
  const mockCalculator = jest.fn();
  
  processOrder(order, { validator: mockValidator, calculator: mockCalculator });
  
  expect(mockValidator).toHaveBeenCalledWith(order);
  expect(mockCalculator).toHaveBeenCalledWith(validatedOrder);
  // This tests implementation, not behavior
});

// Prefer: High-fidelity testing with fakes
it('should process order with validation and pricing', async () => {
  const fakeValidator = new FakeOrderValidator();
  fakeValidator.addValidationRule('minimum-amount', (order) => order.total >= 10);
  
  const fakePricer = new FakeOrderPricer();
  fakePricer.setTaxRate(0.2);
  
  const order = getMockOrder({ total: 50 });
  const result = await processOrder(order, {
    validator: fakeValidator,
    pricer: fakePricer
  });
  
  expect(result.success).toBe(true);
  expect(result.data.finalTotal).toBe(60); // 50 + 20% tax
  
  // Verify realistic end-to-end behavior
  const validationHistory = fakeValidator.getValidationHistory();
  expect(validationHistory).toHaveLength(1);
  expect(validationHistory[^0].passed).toBe(true);
});
```


## Resources and References

- [TypeScript Handbook](https://www.typescriptlang.org/docs/handbook/intro.html)
- [Testing Library Principles](https://testing-library.com/docs/guiding-principles)
- [Kent C. Dodds Testing JavaScript](https://testingjavascript.com/)
- [Google Testing Blog - Increase Test Fidelity by Avoiding Mocks](https://testing.googleblog.com/2024/02/increase-test-fidelity-by-avoiding-mocks.html)
- [Functional Programming in TypeScript](https://gcanti.github.io/fp-ts/)


## Summary

The key is to write clean, testable, functional code that evolves through small, safe increments guided by high-fidelity tests. Every change should be driven by a test that describes the desired behavior using realistic dependencies (fakes) where practical, and the implementation should be the simplest thing that makes that test pass. Higher fidelity testing through fakes over mocks provides greater confidence that your code will work correctly in production while maintaining fast, reliable test execution. When in doubt, favor simplicity, readability, and realistic test scenarios over cleverness.
