import { Knex } from 'knex';
import { PaginationInfo } from '@/module/common/common.type';

export interface PaginationParams {
  page: number;
  limit: number;
  search?: string;
}

export function getPaginationParams(query: { page?: string; limit?: string; search?: string }): PaginationParams {
  const page = Math.max(1, parseInt(query.page || '1', 10));
  const limit = Math.min(50, Math.max(1, parseInt(query.limit || '10', 10)));
  return { page, limit, search: query.search };
}

export function getOffset(params: PaginationParams): number {
  return (params.page - 1) * params.limit;
}

export function buildPaginationInfo(
  total: number,
  params: PaginationParams
): PaginationInfo {
  return {
    page: params.page,
    limit: params.limit,
    total,
    totalPages: Math.ceil(total / params.limit),
  };
}

export async function paginateQuery<T>(
  baseQuery: Knex.QueryBuilder,
  countQuery: Knex.QueryBuilder,
  params: PaginationParams
): Promise<{ data: T[]; pagination: PaginationInfo }> {
  const [{ count }] = await countQuery.count('* as count');
  const total = parseInt(count as string, 10);

  const data = await baseQuery
    .limit(params.limit)
    .offset(getOffset(params)) as T[];

  return {
    data,
    pagination: buildPaginationInfo(total, params),
  };
}
