Example 1 :

  $ publicodes compile example.publicodes -t js -o - | awk '/\/\*\* End embedded runtime \*\//,0'
  /** End embedded runtime */
  
  /** Compiled private Publicodes rules */
  
  /** @type {Fn<number>} */
  function _a(ctx, params) {
    return /** @type {number} */ (
      5.
    )
  }
  
  /** @type {Fn<number>} */
  function _salaire(ctx, params) {
    return /** @type {number} */ (
      $get("salaire", ctx, params)
    )
  }
  
  /** @type {Fn<number>} */
  function _salaire_annuel(ctx, params) {
    return /** @type {number} */ (
      $mul(
        $ref("salaire", _salaire, ctx, params), () => 12.)
    )
  }
  
  /** Exported outputs/inputs */
  
  const rules = {
    'a': {
      /**
       * Parameters of "a"
       * @typedef {{
       * }} aParams
       */
      /**
       * Evaluate "a"
       * @type {(params?: aParams, options?: {cache?: boolean}) => number | undefined | null}
       */
      evaluate: (params = {}, options) =>
        $evaluate(_a, params, options).value,
      /**
       * Evaluate "a" with information on missing and needed parameters
       * @type {(params?: aParams, options?: {cache?: boolean}) => {value: number | undefined | null, needed: Array<keyof aParams>, missing: Array<keyof aParams>}}
       */
      evaluateParams: (params = {}, options) =>
        $evaluate(_a, params, options),
      /** @type {"number"} */
      type: "number",
      /** @type {"aucune"} */
      unit: "aucune",
      /**
       * Parameter list for "a"
       * @type {Array<keyof aParams>}
       */
      params: [],
    },
    'salaire': {
      /**
       * Parameters of "salaire"
       * @typedef {{
       *  'salaire'?: number | undefined
       * }} salaireParams
       */
      /**
       * Evaluate "salaire"
       * @type {(params?: salaireParams, options?: {cache?: boolean}) => number | undefined | null}
       */
      evaluate: (params = {}, options) =>
        $evaluate(_salaire, params, options).value,
      /**
       * Evaluate "salaire" with information on missing and needed parameters
       * @type {(params?: salaireParams, options?: {cache?: boolean}) => {value: number | undefined | null, needed: Array<keyof salaireParams>, missing: Array<keyof salaireParams>}}
       */
      evaluateParams: (params = {}, options) =>
        $evaluate(_salaire, params, options),
      /** @type {"number"} */
      type: "number",
      /** @type {"€/mois"} */
      unit: "€/mois",
      /**
       * Parameter list for "salaire"
       * @type {Array<keyof salaireParams>}
       */
      params: ['salaire'],
    },
    /**
     * **C'est un titre**
     *
     * C'est une description.
     */
    'salaire annuel': {
      /**
       * Parameters of "salaire annuel"
       * @typedef {{
       *  'salaire'?: number | undefined
       * }} salaire_annuelParams
       */
      /**
       * Evaluate "salaire annuel"
       * @type {(params?: salaire_annuelParams, options?: {cache?: boolean}) => number | undefined | null}
       */
      evaluate: (params = {}, options) =>
        $evaluate(_salaire_annuel, params, options).value,
      /**
       * Evaluate "salaire annuel" with information on missing and needed parameters
       * @type {(params?: salaire_annuelParams, options?: {cache?: boolean}) => {value: number | undefined | null, needed: Array<keyof salaire_annuelParams>, missing: Array<keyof salaire_annuelParams>}}
       */
      evaluateParams: (params = {}, options) =>
        $evaluate(_salaire_annuel, params, options),
      /** @type {"number"} */
      type: "number",
      /** @type {"€/mois"} */
      unit: "€/mois",
      /**
       * Parameter list for "salaire annuel"
       * @type {Array<keyof salaire_annuelParams>}
       */
      params: ['salaire'],
      /** @type {string} */
      title: 'C\'est un titre',
      /** @type {string} */
      description: 'C\'est une description.',
      /** @type {string} */
      note: 'Attention, c\'est une règle importante.\n',
    }
  }
  
  export default rules;
