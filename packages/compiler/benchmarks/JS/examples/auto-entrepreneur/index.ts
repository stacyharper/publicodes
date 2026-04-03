import { run, bench, summary, do_not_optimize } from 'mitata'

import LegacyEngine from 'publicodes'

// Test data imports
import autoEntrepreneurLegacyRules from './publicodes-build/index.js'
import rules from './model.publicodes.js'

console.log('🚀 Publicodes Engine Benchmark - auto-entrepreneur modèle \n')

const situationBuilder = ({ legacy }) => ({
	"entreprise . chiffre d'affaires . BIC": 0,
	"entreprise . chiffre d'affaires . service BIC": 10000,
	"entreprise . chiffre d'affaires . service BNC": 0,
	"entreprise . chiffre d'affaires . vente restauration hébergement": 0,
	'entreprise . activité . nature': legacy ? "'libérale'" : 'libérale',
	'entreprise . activité . nature . libérale . réglementée':
		legacy ? 'non' : false,
	date: legacy ? '20/05/2025' : new Date('2025-05-20'),
	'dirigeant . auto-entrepreneur . Cipav . adhérent': legacy ? 'non' : false,
})

const situation = situationBuilder({ legacy: true })
const contexte = situationBuilder({ legacy: false })

summary(() => {
	const legacyEngineAE = new LegacyEngine(autoEntrepreneurLegacyRules)

	bench('[Evaluation cache reset] Publicodes 1', () => {
		legacyEngineAE.setSituation(situation)
		return legacyEngineAE.evaluate('dirigeant . auto-entrepreneur . revenu net')
			.nodeValue
	})

	bench('[Evaluation without cache] Publicodes 2 (JS)', () => {
		return rules['dirigeant . auto-entrepreneur . revenu net'].evaluate(
			contexte,
		)
	})
})

summary(() => {
	const legacyEngineAE = new LegacyEngine(autoEntrepreneurLegacyRules)

	legacyEngineAE.setSituation(situation)
	bench('[Same evaluation repeated] Publicodes 1', () => {
		return legacyEngineAE.evaluate('dirigeant . auto-entrepreneur . revenu net')
			.nodeValue
	})

	// Auto-entrepreneur model evaluations
	bench('[Same evaluation repeated] Publicodes 2 (with cache)', () => {
		return rules['dirigeant . auto-entrepreneur . revenu net'].evaluate(
			contexte,
			{ cache: true },
		)
	})

	// Auto-entrepreneur model evaluations
	bench('[Same evaluation repeated] Publicodes 2 (without cache)', () => {
		return rules['dirigeant . auto-entrepreneur . revenu net'].evaluate(
			contexte,
		)
	})
})
//
// FIXME: legacy engine does not return the same results as new engine
const testRules = [
	{ rule: 'dirigeant . auto-entrepreneur . revenu net', value: undefined },
	{ rule: 'entreprise . activité . nature', value: 'libérale' },
	{
		rule: 'dirigeant . auto-entrepreneur . cotisations et contributions',
		value: undefined,
	},
	{
		rule: 'dirigeant . auto-entrepreneur . cotisations et contributions . cotisations',
		value: undefined,
	},
	{
		rule: 'dirigeant . auto-entrepreneur . cotisations et contributions . TFC',
		value: 0,
	},
	{ rule: "entreprise . chiffre d'affaires", value: 10000 },
]

// Complex scenario benchmarks for auto-entrepreneur
summary(() => {
	const legacyEngineAE = new LegacyEngine(autoEntrepreneurLegacyRules)
	bench('[Multiple rules evaluated first eval] Publicodes 1', () => {
		legacyEngineAE.setSituation(situation)
		testRules.forEach(({ rule }) => {
			legacyEngineAE.evaluate(rule)
		})
	})

	bench(
		'[Multiple rules evaluated first eval] Publicodes 2 (with cache)',
		() => {
			const newContexte = Object.assign({}, contexte)
			testRules.forEach(({ rule }) =>
				rules[rule].evaluate(newContexte, { cache: true }),
			)
		},
	)

	bench(
		'[Multiple rules evaluated first eval] Publicodes 2 (without cache)',
		() => {
			const newContexte = Object.assign({}, contexte)
			testRules.forEach(({ rule }) => rules[rule].evaluate(newContexte))
		},
	)
})

// Complex scenario benchmarks for auto-entrepreneur
summary(() => {
	const changes = {
		"entreprise . chiffre d'affaires . service BNC": 10000,
		"entreprise . chiffre d'affaires . service BIC": 10000,
	}

	const legacyEngineAE = new LegacyEngine(autoEntrepreneurLegacyRules)
	bench('[Multiple engine comparison] Publicodes 1', () => {
		;[(situation, Object.assign({}, situation, changes))].forEach((s) => {
			const engine = legacyEngineAE.shallowCopy()
			engine.setSituation(s)
			testRules.forEach(({ rule }) => engine.evaluate(rule))
		})
	})

	bench('[Multiple engine comparison] Publicodes 2 (with cache)', () => {
		const c1 = Object.assign({}, contexte)
		const c2 = Object.assign({}, contexte, changes)
		;[(c1, c2)].forEach((c) =>
			testRules.forEach(({ rule }) =>
				do_not_optimize(rules[rule].evaluate(c, { cache: true })),
			),
		)
	})

	// const newEngineJSAEWithoutCache = new NewEngineJS()
	bench('[Multiple engine comparison] Publicodes 2 (without cache)', () => {
		const c1 = Object.assign({}, contexte)
		const c2 = Object.assign({}, contexte, changes)
		;[c1, c2].forEach((c) =>
			do_not_optimize(testRules.forEach(({ rule }) => rules[rule].evaluate(c))),
		)
	})
})

await run({
	format: 'mitata',
	throw: true,
})
