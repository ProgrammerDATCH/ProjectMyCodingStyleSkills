---
name: express-prisma-api
description: >-
  David's standard for building standalone backend REST APIs with Express +
  TypeScript + Prisma (MySQL). Use whenever creating or editing an Express/Node
  API server, adding an endpoint, controller, service, route, Joi validation,
  middleware, or Prisma model in his repos (e.g. Ireme backends). Covers the
  layered architecture (routes → middleware → controllers → services), the
  ApiError/ERROR_CODES error model, the sendResponse envelope, catchAsync, JWT
  auth, winston logging, path aliases, and the Docker→ghcr.io→ssh deploy flow.
  This is the default backend for new APIs. Pair with coding-principles.
---

# Express + TypeScript + Prisma API (David's standard)

Default stack for any **standalone** backend API. (For a single Next.js dashboard,
keep server logic in `app/api/*/route.ts` instead — see `nextjs-dashboard`.)

## Stack

Express 4 · TypeScript · Prisma + MySQL (`mysql2`) · Joi · JWT + passport-jwt ·
winston (+ daily rotate) · helmet · cors · compression · morgan · http-status ·
swagger-ui-express. Path alias `@/*` → `src/*`. Dev via nodemon + ts-node;
build via `prisma generate && tsc && tsc-alias`.

## Layered architecture (strict)

```
src/
  config/        prisma.ts, logger.ts, config.ts, template.ts
  middleware/    auth.ts, validation.ts, error.ts
  routes/        one router per resource → mounted in routes/index.ts
  controllers/   thin: parse req, call service, sendResponse
  services/      ALL business logic + Prisma access; throw ApiError
  validations/   Joi schemas + shared patterns.ts
  utils/         catchAsync, response, ApiError, errorCodes, <domain>Utils
  types/         api.ts (domain models, enums like UserRole), express.d.ts
```

Request flow: **route → auth() → validation(schema) → controller(Handler) → service → prisma**.
Controllers never touch Prisma. Services never touch `req`/`res`.

## The reusable primitives — always use these

`catchAsync` wraps every async controller so errors reach the error middleware:

```ts
// utils/catchAsync.ts
const catchAsync = (fn: RequestHandler) =>
  (req: Request, res: Response, next: NextFunction) =>
    Promise.resolve(fn(req, res, next)).catch(next);
export default catchAsync;
```

`sendResponse` is the single response envelope:

```ts
// utils/response.ts
export interface ApiResponse<T = unknown> {
  status: 'success' | 'error';
  message: string;
  data?: T;
  errorCode?: string;
}
export function sendResponse<T>(res, statusCode, message, data?, errorCode?) {
  const body: ApiResponse<T> = { status: errorCode ? 'error' : 'success', message };
  if (data !== undefined) body.data = data;
  if (errorCode) body.errorCode = errorCode;
  return res.status(statusCode).json(body);
}
```

`ApiError` + `ERROR_CODES` — operational errors carry an HTTP status, a message, and a
stable code (`E1002`, …). Add new codes to `utils/errorCodes.ts`, grouped by domain.

```ts
throw new ApiError(httpStatus.NOT_FOUND, 'User not found', ERROR_CODES.USER_NOT_FOUND);
```

## Controller template (thin)

```ts
import { Request, Response } from 'express';
import httpStatus from 'http-status';
import catchAsync from '@/utils/catchAsync';
import { sendResponse } from '@/utils/response';
import { createUser } from '@/services/userService';

export const createUserHandler = catchAsync(async (req: Request, res: Response) => {
  const result = await createUser(req.body);
  sendResponse(res, httpStatus.CREATED, result.message, result.data);
});
```

Controllers pull `req.params` / `req.body` / `req.query`, call one service, and
`sendResponse`. Services return `{ message, data }`.

## Service template (all logic + Prisma)

```ts
import prisma from '@/config/prisma';
import ApiError from '@/utils/ApiError';
import { ERROR_CODES } from '@/utils/errorCodes';
import status from 'http-status';

export const createUser = async (input: CreateUserInput) => {
  const exists = await prisma.user.findFirst({ where: { email: input.email, isActive: true } });
  if (exists) throw new ApiError(status.CONFLICT, 'Email already exists', ERROR_CODES.EMAIL_ALREADY_EXISTS);

  const user = await prisma.user.create({ data: { ...input } });
  return { message: 'User created', data: transformUser(user) };
};
```

- Shape Prisma rows into typed domain models before returning — a `transformPrismaData`
  / `transformUser` helper, mapping `null → undefined` and dropping internal fields.
- Soft-delete / active filtering: query with `isActive: true` where the model supports it.
- Validate uniqueness/existence in the service and throw the right `ApiError`.

## Route template

```ts
import { Router } from 'express';
import auth from '@/middleware/auth';
import validation from '@/middleware/validation';
import { UserRole } from '@/types/api';
import { createUserHandler } from '@/controllers/userController';
import { createUserSchema } from '@/validations/userValidation';

const router = Router();
router.post('/', auth(UserRole.ADMIN), validation(createUserSchema), createUserHandler);
export default router;
```

## Validation — Joi with shared patterns

Schemas live in `validations/`. Reuse `commonSchemas` and the `optionalOrEmpty()` helper
from `validations/patterns.ts` instead of re-declaring rules.

```ts
import Joi from 'joi';
import { commonSchemas, optionalOrEmpty } from './patterns';

export const createUserSchema = Joi.object({
  firstName: commonSchemas.firstName.required(),
  email: commonSchemas.email.required(),
  phone: optionalOrEmpty(commonSchemas.phone),
});
```

The `validation` middleware runs `{ abortEarly: false }`, normalises the message, and on
failure returns `sendResponse(res, 400, message, null, ERROR_CODES.VALIDATION_ERROR)`.
On success it assigns the coerced `value` back to `req.body`.

## Auth & roles

`auth(...allowedRoles)` middleware: reads `Bearer` token, `jwt.verify` with
`config.jwt.secret`, loads the active user via Prisma `select`, checks role membership,
attaches `req.user`. Access/refresh tokens + a sessions table for revocation. Throw
`ApiError(UNAUTHORIZED|FORBIDDEN, …)` — never return ad-hoc JSON from middleware.

## Cross-cutting

- **Error middleware** (`middleware/error.ts`) is mounted last; converts `ApiError`
  (and unknown errors → 500 `INTERNAL_SERVER_ERROR`) into the `sendResponse` envelope
  and logs via winston.
- **Logging**: winston (`config/logger.ts`) with daily-rotate files in `logs/`. No
  `console.log` in committed code.
- **Config**: read env once in `config/config.ts`; ship `example.env`; never hard-code
  secrets. Prisma client is a singleton in `config/prisma.ts`.
- **Swagger**: keep `swagger.json` / annotations current when adding endpoints.

## Scripts & deploy

Mirror the existing `package.json`: `dev` (nodemon+ts-node), `build`
(`prisma generate && tsc && tsc-alias`), and `db:*` (`migrate`, `push`, `seed`, `studio`,
`reset`). Seed/maintenance scripts go in `scripts/` and run via
`ts-node -r tsconfig-paths/register`. Deploy = build → `docker build` → push to
`ghcr.io/programmerdatch/...` → ssh to the server → `docker compose pull && up -d`.

## Do / Don't

**Do** keep controllers thin · put all logic in services · throw `ApiError` with a code ·
return `{ message, data }` from services · reuse `commonSchemas`/`optionalOrEmpty` ·
type request inputs.

**Don't** access Prisma from a controller · touch `req`/`res` in a service · return raw
Prisma rows (transform first) · invent a new response shape · `console.log` · hard-code
secrets, status strings, or error messages that should be `ERROR_CODES`.
