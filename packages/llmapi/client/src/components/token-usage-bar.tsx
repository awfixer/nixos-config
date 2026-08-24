import { useEffect, useRef, useState } from 'react'
import { useQuery } from '@tanstack/react-query'
import { ChevronDown } from 'lucide-react'
import { useI18n } from '@/i18n'
import { apiFetch } from '@/lib/api'
import { formatPercent, formatTokens, platformColors, type TokenUsageData } from '@/lib/routing'

// Legend rows visible while collapsed (~6 rows: 6 × 16px line + 5 × 6px gap).
const LEGEND_COLLAPSED_PX = 126

// Stacked monthly token-budget bar with a collapsible per-model legend,
// extracted from FallbackPage.
export function TokenUsageBar({ data }: { data: TokenUsageData }) {
  const { t } = useI18n()
  const { totalBudget, totalUsed, models } = data
  const remaining = Math.max(0, totalBudget - totalUsed)
  const remainingPct = totalBudget > 0 ? formatPercent(remaining / totalBudget) : '0%'

  const modelsWithWidth = models.map(m => {
    const usedTokens = m.used ?? 0
    const remainingTokens = Math.max(0, m.budget - usedTokens)
    return {
      ...m,
      usedTokens,
      remainingTokens,
      widthPct: totalBudget > 0 ? (remainingTokens / totalBudget) * 100 : 0,
    }
  })
  const usedPct = totalBudget > 0 ? Math.min(100, (totalUsed / totalBudget) * 100) : 0

  // A model with no published monthly quota has nothing to say in a
  // remaining/budget legend, and one provider can contribute a hundred of them
  // (#887) — drowning the models that do have a budget. Count them instead.
  const budgeted = modelsWithWidth.filter(m => m.budget > 0)
  const unpublishedCount = modelsWithWidth.length - budgeted.length

  // Collapse the per-model legend to a few rows; the chevron reveals the rest.
  // The toggle only appears when the legend actually overflows the collapsed
  // height (column count — and so row count — depends on viewport width).
  const [expanded, setExpanded] = useState(false)
  const [collapsible, setCollapsible] = useState(false)
  const legendRef = useRef<HTMLDivElement>(null)
  useEffect(() => {
    const el = legendRef.current
    if (!el) return
    const check = () => setCollapsible(el.scrollHeight > LEGEND_COLLAPSED_PX + 1)
    check()
    const ro = new ResizeObserver(check)
    ro.observe(el)
    return () => ro.disconnect()
  }, [budgeted.length, unpublishedCount])

  return (
    <section className="rounded-3xl border bg-card p-5">
      <div className="flex items-baseline justify-between mb-3">
        <h2 className="text-sm font-medium">{t('models.monthlyTokenBudget')}</h2>
        <span className="text-xs text-muted-foreground tabular-nums">
          <span className="text-foreground font-medium">{formatTokens(remaining)}</span> {t('models.remaining')}
          <span className="mx-1.5">·</span>
          {remainingPct} {t('models.of')} {formatTokens(totalBudget)}
          {totalUsed > 0 && (
            <>
              <span className="mx-1.5">·</span>
              {/* Say out loud what this number counts (#887): it is not the
                  analytics total, and custom endpoints are in it. */}
              <span className="cursor-help underline decoration-dotted underline-offset-2" title={t('models.usedScopeHint')}>
                <span className="text-foreground font-medium">{formatTokens(totalUsed)}</span> {t('models.used')}
              </span>
            </>
          )}
        </span>
      </div>

      <div className="flex h-2.5 rounded-full overflow-hidden bg-muted">
        {modelsWithWidth.map((m, i) => (
          <div
            key={i}
            title={`${m.displayName} (${m.platform}): ${formatTokens(m.remainingTokens)} ${t('models.remaining')}, ${formatTokens(m.usedTokens)} ${t('models.used')}`}
            style={{
              width: `${m.widthPct}%`,
              backgroundColor: platformColors[m.platform] ?? '#94a3b8',
            }}
          />
        ))}
        {totalUsed > 0 && (
          <div
            title={`Used: ${formatTokens(totalUsed)}`}
            className="bg-muted-foreground/30"
            style={{ width: `${usedPct}%` }}
          />
        )}
      </div>

      <div
        ref={legendRef}
        className="mt-4 overflow-hidden transition-[max-height] duration-300 ease-in-out"
        style={collapsible ? { maxHeight: expanded ? legendRef.current?.scrollHeight : LEGEND_COLLAPSED_PX } : undefined}
      >
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-x-5 gap-y-1.5 text-xs tabular-nums">
          {budgeted.map((m, i) => (
            <div key={i} className="flex items-center gap-2 min-w-0">
              <span
                className="size-2 rounded-sm flex-shrink-0"
                style={{ backgroundColor: platformColors[m.platform] ?? '#94a3b8' }}
              />
              <span className="truncate">{m.displayName}</span>
              <span className="flex-1" />
              {/* remaining / budget: a bare remaining figure gives no sense of
                  how much of the allowance is gone (#887). */}
              <span
                className="font-mono text-muted-foreground"
                title={t('models.legendRemainingTitle', { name: m.displayName, platform: m.platform })}
              >
                {formatTokens(m.remainingTokens)}<span className="mx-0.5">/</span>{formatTokens(m.budget)}
              </span>
            </div>
          ))}
        </div>
      </div>

      {/* Outside the collapsible box on purpose: it is a summary of what the
          legend is NOT showing, so it has to stay visible while collapsed. */}
      {unpublishedCount > 0 && (
        <p className="mt-1.5 text-xs text-muted-foreground" title={t('models.noPublishedQuotaTitle')}>
          {t('models.noPublishedQuota', { count: unpublishedCount })}
        </p>
      )}

      {collapsible && (
        <button
          onClick={() => setExpanded(e => !e)}
          className="mt-2 flex w-full items-center justify-center gap-1 text-xs text-muted-foreground hover:text-foreground transition-colors"
        >
          {expanded ? t('models.showLess') : t('models.showAllModels', { count: budgeted.length })}
          <ChevronDown className={`size-3.5 transition-transform duration-300 ${expanded ? 'rotate-180' : ''}`} />
        </button>
      )}

      <FreeTierPools />
    </section>
  )
}

interface FreeTierPool {
  poolKey: string
  platform: string
  modelCount: number
  disabledModelCount: number
  keyCount: number
  documentedBudget: number
  bestLabel: string
  kind: 'documented' | 'credits' | 'unpublished'
  quota: {
    limit: number | null
    remaining: number | null
    resetAt: string | null
    metric: string
    keyCount: number
  } | null
}

interface FreeTierResponse {
  generatedAt: string
  summary: {
    poolCount: number
    documentedMonthlyTokens: number
    creditsBasedPools: number
    unpublishedPools: number
  }
  pools: FreeTierPool[]
}

const METRIC_KEYS: Record<string, string> = {
  tokens: 'freeTier.metricTokens',
  requests: 'freeTier.metricRequests',
  credits: 'freeTier.metricCredits',
  neurons: 'freeTier.metricNeurons',
}

// Pool-deduped free-tier budgets (#905). The stacked bar above sums per model,
// which double-counts every model sharing one provider allowance; this is the
// same capacity counted once per pool. It is a detail view, so it lives as a
// collapsed row under the bar rather than as its own page — and it only fetches
// once someone opens it.
function FreeTierPools() {
  const { t } = useI18n()
  const [open, setOpen] = useState(false)
  const { data } = useQuery({
    queryKey: ['free-tier'],
    queryFn: () => apiFetch<FreeTierResponse>('/api/free-tier'),
    enabled: open,
  })

  return (
    <div className="mt-3 border-t pt-2">
      <button
        onClick={() => setOpen(o => !o)}
        className="flex w-full items-center justify-center gap-1 text-xs text-muted-foreground hover:text-foreground transition-colors"
        aria-expanded={open}
      >
        {data ? t('freeTier.poolsToggle', { count: data.summary.poolCount }) : t('freeTier.poolsToggleBare')}
        <ChevronDown className={`size-3.5 transition-transform duration-300 ${open ? 'rotate-180' : ''}`} />
      </button>

      {open && data && (
        <div className="mt-3">
          <p className="text-xs text-muted-foreground mb-2">
            {t('freeTier.summary', {
              pools: data.summary.poolCount,
              budget: formatTokens(data.summary.documentedMonthlyTokens),
              credits: data.summary.creditsBasedPools,
              unpublished: data.summary.unpublishedPools,
            })}
          </p>
          {data.pools.length === 0 ? (
            <p className="text-xs text-muted-foreground py-2">{t('freeTier.empty')}</p>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full text-xs tabular-nums">
                <thead className="text-muted-foreground">
                  <tr className="border-b">
                    <th className="text-left font-normal py-1.5 pr-3">{t('freeTier.pool')}</th>
                    <th className="text-right font-normal py-1.5 px-3">{t('freeTier.models')}</th>
                    <th className="text-right font-normal py-1.5 px-3">{t('freeTier.budget')}</th>
                    <th className="text-left font-normal py-1.5 px-3">{t('freeTier.kind')}</th>
                    <th className="text-right font-normal py-1.5 px-3">{t('freeTier.remaining')}</th>
                    <th className="text-left font-normal py-1.5 pl-3">{t('freeTier.resetAt')}</th>
                  </tr>
                </thead>
                <tbody>
                  {data.pools.map(p => (
                    <tr key={p.poolKey} className="border-b last:border-0">
                      <td className="py-1.5 pr-3">
                        <span className="inline-flex items-center gap-2 min-w-0">
                          <span
                            className="size-2 rounded-sm flex-shrink-0"
                            style={{ backgroundColor: platformColors[p.platform] ?? '#94a3b8' }}
                          />
                          <span className="truncate font-mono">{p.poolKey}</span>
                        </span>
                      </td>
                      <td className="text-right py-1.5 px-3">
                        {p.modelCount}
                        {p.disabledModelCount > 0 && (
                          <span className="text-muted-foreground">
                            {' '}
                            {t('freeTier.disabledModels', { count: p.disabledModelCount })}
                          </span>
                        )}
                      </td>
                      <td className="text-right py-1.5 px-3">
                        {p.documentedBudget > 0 ? formatTokens(p.documentedBudget) : '—'}
                      </td>
                      <td className="py-1.5 px-3 text-muted-foreground">
                        {t(`freeTier.kind${p.kind === 'documented' ? 'Documented' : p.kind === 'credits' ? 'Credits' : 'Unpublished'}`)}
                      </td>
                      <td className="text-right py-1.5 px-3">
                        {p.quota?.remaining != null ? (
                          <>
                            {formatTokens(p.quota.remaining)}{' '}
                            {/* Always say WHICH budget the number counts: a
                                request counter next to a token budget reads as
                                tokens otherwise. */}
                            <span className="text-muted-foreground">
                              {t(METRIC_KEYS[p.quota.metric] ?? 'freeTier.metricOther')}
                            </span>
                          </>
                        ) : (
                          '—'
                        )}
                      </td>
                      <td className="py-1.5 pl-3 text-muted-foreground whitespace-nowrap">
                        {p.quota?.resetAt ? new Date(p.quota.resetAt).toLocaleString() : '—'}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>
      )}
    </div>
  )
}
