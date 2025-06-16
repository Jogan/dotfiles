# Project Context for Claude Code

## Project Overview
<!-- Brief description of what this project does -->

## Tech Stack
<!-- List the main technologies, frameworks, and tools used -->
- Language: 
- Framework: 
- Database: 
- Testing: 
- Build Tool: 
- Package Manager: 

## Project Structure
```
<!-- Describe your key directories and files -->
src/
├── components/     # Reusable UI components
├── pages/         # Application pages/routes
├── services/      # API calls and business logic
├── utils/         # Helper functions and utilities
├── types/         # Type definitions
└── tests/         # Test files
```

## Development Commands
<!-- Common commands you use during development -->
- **Install dependencies**: `npm install` or `yarn install`
- **Start development server**: `npm run dev` or `yarn dev`
- **Run tests**: `npm test` or `yarn test`
- **Build for production**: `npm run build` or `yarn build`
- **Lint code**: `npm run lint` or `yarn lint`
- **Type check**: `npm run typecheck` or `yarn typecheck`

## Code Style & Conventions
<!-- Your coding standards and preferences -->
- **Naming**: Use camelCase for variables and functions, PascalCase for components
- **File naming**: Use kebab-case for file names
- **Import order**: External libraries first, then internal modules
- **Comments**: Use JSDoc for functions, inline comments for complex logic
- **Error handling**: Always handle errors gracefully with try/catch

## Testing Strategy
<!-- How tests are organized and what to test -->
- **Unit tests**: Test individual functions and components
- **Integration tests**: Test component interactions
- **E2E tests**: Test user workflows
- **Test location**: Tests should be co-located with source files or in `__tests__` directory

## Key Files & Their Purpose
<!-- Important files Claude should know about -->
- `package.json`: Project dependencies and scripts
- `tsconfig.json`: TypeScript configuration
- `.env`: Environment variables (never commit secrets!)
- `README.md`: Project documentation

## Common Issues & Solutions
<!-- Frequent problems and how to solve them -->
- **Build fails**: Check for TypeScript errors and missing dependencies
- **Tests failing**: Ensure test environment is properly configured
- **Performance issues**: Look for unnecessary re-renders and large bundle sizes

## Deployment Notes
<!-- Deployment-specific information -->
- **Environment**: 
- **Build command**: 
- **Deploy command**: 
- **Environment variables needed**: 

## Additional Context
<!-- Any other important information for Claude to know -->
- **API documentation**: 
- **Design system**: 
- **Legacy code considerations**: 
- **Performance requirements**: 

---
*This file helps Claude Code understand your project better. Update it as your project evolves.*