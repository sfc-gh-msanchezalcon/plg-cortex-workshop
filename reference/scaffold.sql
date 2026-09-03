-- ============================================================================
-- PLG Cortex Workshop — MASTER ANSWER KEY (scaffold.sql)
-- ----------------------------------------------------------------------------
-- Every DDL/query the workshop builds, in one place. Use it if you get stuck,
-- or to run any stage's "fast-path" from a worksheet. The notebooks contain the
-- same SQL with the key lines blanked out for you to complete.
--
-- Assumes 00_setup.ipynb has already created:
--   DB        : PLG_CORTEX_WORKSHOP
--   Warehouse : PLG_WORKSHOP_WH   (shared, MEDIUM, multi-cluster)
--   Schema    : PLG_CORTEX_WORKSHOP.WS_<your_user>   (your private sandbox)
-- and that you have run  USE SCHEMA / USE WAREHOUSE  for your sandbox.
-- ============================================================================


-- ============================================================================
-- STAGE 0 — SETUP + SYNTHETIC DATA  (setup/00_setup.ipynb)
-- ============================================================================

-- 0.1  Shared database + warehouse (safe to run repeatedly; first person wins)
CREATE DATABASE IF NOT EXISTS PLG_CORTEX_WORKSHOP;

CREATE WAREHOUSE IF NOT EXISTS PLG_WORKSHOP_WH
  WAREHOUSE_SIZE = 'MEDIUM'
  AUTO_SUSPEND = 60
  AUTO_RESUME = TRUE
  INITIALLY_SUSPENDED = TRUE
  MIN_CLUSTER_COUNT = 1
  MAX_CLUSTER_COUNT = 3
  COMMENT = 'Shared warehouse for the PLG Cortex workshop';

-- 0.2  Your own private sandbox schema (named after your user)
SET ws  = REGEXP_REPLACE(CURRENT_USER(), '[^A-Za-z0-9_]', '_');
SET sch = 'PLG_CORTEX_WORKSHOP.WS_' || $ws;
CREATE SCHEMA IF NOT EXISTS IDENTIFIER($sch);

USE WAREHOUSE PLG_WORKSHOP_WH;
USE SCHEMA IDENTIFIER($sch);

-- 0.3  Generate synthetic survey data.
--      Change 4000 below to scale (e.g. 20000). ~4k keeps the whole lab fast.
CREATE OR REPLACE TRANSIENT TABLE _SURVEY_RAW AS
WITH base AS (
  SELECT
    SEQ8()                              AS n,
    UNIFORM(1, 100, RANDOM())           AS mood,
    UNIFORM(1, 1500, RANDOM())          AS player_seed,
    UNIFORM(0, 1, RANDOM())             AS brand_pick,
    UNIFORM(0, 3, RANDOM())             AS email_pick,
    UNIFORM(0, 720, RANDOM())           AS day_offset,
    UNIFORM(0, 4, RANDOM())             AS neg_idx,
    UNIFORM(0, 4, RANDOM())             AS neu_idx,
    UNIFORM(0, 4, RANDOM())             AS pos_idx,
    UNIFORM(0, 3, RANDOM())             AS junk_idx,
    UNIFORM(0, 4, RANDOM())             AS tneg_idx,
    UNIFORM(0, 4, RANDOM())             AS tpos_idx,
    UNIFORM(1, 100, RANDOM())           AS junk_roll,
    UNIFORM(1, 100000, RANDOM())        AS round_seed
  FROM TABLE(GENERATOR(ROWCOUNT => 4000))
)
SELECT
  'R'  || LPAD(n::string, 7, '0')                                       AS response_id,
  'P'  || LPAD(player_seed::string, 5, '0')                             AS player_id,
  'GR' || LPAD(round_seed::string, 7, '0')                              AS game_round_id,
  CASE WHEN brand_pick = 0 THEN 'NPL' ELSE 'VriendenLoterij' END        AS brand,
  GET(ARRAY_CONSTRUCT('welcome','prize_notification','monthly_update','winback'), email_pick)::string AS email_type,
  DATEADD('day', -day_offset, CURRENT_DATE())                           AS survey_date,
  CASE WHEN mood <= 30 THEN 'poor' WHEN mood <= 70 THEN 'normal' ELSE 'good' END AS game_round_performance,
  ROUND(CASE WHEN mood <= 30 THEN UNIFORM(0.0, 0.3, RANDOM())
             WHEN mood <= 70 THEN UNIFORM(0.2, 0.6, RANDOM())
             ELSE UNIFORM(0.5, 0.95, RANDOM()) END, 2)                  AS replay_rate,
  CASE WHEN mood <= 30 THEN UNIFORM(1,3,RANDOM())
       WHEN mood <= 70 THEN UNIFORM(2,4,RANDOM())
       ELSE UNIFORM(4,5,RANDOM()) END                                   AS clarity_rating,
  CASE WHEN mood <= 30 THEN UNIFORM(1,3,RANDOM())
       WHEN mood <= 70 THEN UNIFORM(2,4,RANDOM())
       ELSE UNIFORM(3,5,RANDOM()) END                                   AS tone_rating,
  -- Clarity free text (Dutch), correlated with mood; ~8% junk answers
  CASE
    WHEN junk_roll <= 8 THEN GET(ARRAY_CONSTRUCT('nee','nvt','geen','-'), junk_idx)::string
    WHEN mood <= 30 THEN GET(ARRAY_CONSTRUCT(
        'De e-mail was verwarrend, ik snapte niet wat ik moest doen.',
        'Te veel tekst en onduidelijke uitleg over de trekking.',
        'Ik begreep de actievoorwaarden totaal niet.',
        'Onduidelijk welke prijs ik had gewonnen.',
        'De knop werkte niet en de instructies klopten niet.'), neg_idx)::string
    WHEN mood <= 70 THEN GET(ARRAY_CONSTRUCT(
        'Redelijk duidelijk, maar kan korter.',
        'Grotendeels helder, een paar zinnen waren wat lang.',
        'Prima, al miste ik wat details over de einddatum.',
        'Op zich oke, de layout mag rustiger.',
        'Voldoende duidelijk voor mij.'), neu_idx)::string
    ELSE GET(ARRAY_CONSTRUCT(
        'Heel duidelijke e-mail, precies wat ik nodig had.',
        'Fijn en helder geschreven, top.',
        'Duidelijke uitleg over mijn prijs, dank!',
        'Prettige toon en goed leesbaar.',
        'Alles was meteen duidelijk.'), pos_idx)::string
  END                                                                   AS clarity_comment,
  -- Tone free text (Dutch), correlated with mood
  CASE
    WHEN junk_roll BETWEEN 90 AND 94 THEN GET(ARRAY_CONSTRUCT('nvt','nee','-','geen mening'), junk_idx)::string
    WHEN mood <= 30 THEN GET(ARRAY_CONSTRUCT(
        'De toon voelde afstandelijk en onpersoonlijk.',
        'Kwam nogal pusherig over.',
        'Te commercieel, niet echt vriendelijk.',
        'Ik voelde me niet serieus genomen.',
        'De toon was koel en zakelijk.'), tneg_idx)::string
    WHEN mood <= 70 THEN GET(ARRAY_CONSTRUCT(
        'Neutrale toon, prima.',
        'Vriendelijk genoeg.',
        'Zakelijk maar oke.',
        'Niet storend, niet bijzonder.',
        'Redelijk warme toon.'), neu_idx)::string
    ELSE GET(ARRAY_CONSTRUCT(
        'Warme, persoonlijke toon. Voelde vriendelijk.',
        'Heel prettig en respectvol geschreven.',
        'Enthousiaste en positieve toon, leuk!',
        'Voelde persoonlijk en betrokken.',
        'Fijne, gastvrije toon.'), tpos_idx)::string
  END                                                                   AS tone_comment
FROM base;

-- 0.4  Split into the three tables the workshop joins (clean 1:1 grain)
CREATE OR REPLACE TABLE SURVEY_RESPONSES AS
  SELECT response_id, player_id, game_round_id, brand, email_type, survey_date,
         clarity_rating, tone_rating, clarity_comment, tone_comment
  FROM _SURVEY_RAW;

CREATE OR REPLACE TABLE GAME_ROUNDS AS
  SELECT game_round_id, player_id, survey_date AS round_date, game_round_performance
  FROM _SURVEY_RAW;

CREATE OR REPLACE TABLE PLAYER_BEHAVIOUR AS
  SELECT player_id,
         AVG(replay_rate)  AS replay_rate,
         COUNT(*)          AS surveys_answered
  FROM _SURVEY_RAW
  GROUP BY player_id;

DROP TABLE IF EXISTS _SURVEY_RAW;

-- 0.5  Self-check: expected shape
SELECT 'SURVEY_RESPONSES' AS tbl, COUNT(*) AS rows FROM SURVEY_RESPONSES
UNION ALL SELECT 'GAME_ROUNDS', COUNT(*) FROM GAME_ROUNDS
UNION ALL SELECT 'PLAYER_BEHAVIOUR', COUNT(*) FROM PLAYER_BEHAVIOUR;
-- Expect ~4000 survey rows, ~4000 game rounds, <=1500 players.


-- ============================================================================
-- STAGE 1 — FOUNDATION: base view + semantic view  (01_foundation...)
-- ============================================================================

-- 1.1  A clean base view. Grain = ONE row per survey response (no fan-out,
--      because each response references exactly one game round + one player).
CREATE OR REPLACE VIEW SURVEY_BASE AS
SELECT
  s.response_id,
  s.player_id,
  s.brand,
  s.email_type,
  s.survey_date,
  s.clarity_rating,
  s.tone_rating,
  s.clarity_comment,
  s.tone_comment,
  g.game_round_performance,
  b.replay_rate
FROM SURVEY_RESPONSES s
JOIN GAME_ROUNDS       g ON s.game_round_id = g.game_round_id
JOIN PLAYER_BEHAVIOUR  b ON s.player_id     = b.player_id;

-- 1.2  Semantic view for Cortex Analyst.
--      Order matters: TABLES -> RELATIONSHIPS -> FACTS -> DIMENSIONS -> METRICS.
CREATE OR REPLACE SEMANTIC VIEW SURVEY_ANALYSIS
  TABLES (
    responses AS SURVEY_RESPONSES
      PRIMARY KEY (response_id)
      WITH SYNONYMS ('survey', 'feedback', 'email survey')
      COMMENT = 'One row per player email-survey response (clarity + tone)',
    rounds AS GAME_ROUNDS
      PRIMARY KEY (game_round_id)
      COMMENT = 'The game round that triggered each survey',
    players AS PLAYER_BEHAVIOUR
      PRIMARY KEY (player_id)
      COMMENT = 'Player-level behaviour (replay rate)'
  )
  RELATIONSHIPS (
    resp_to_round  AS responses (game_round_id) REFERENCES rounds (game_round_id),
    resp_to_player AS responses (player_id)     REFERENCES players (player_id)
  )
  FACTS (
    responses.clarity_rating AS clarity_rating,
    responses.tone_rating    AS tone_rating,
    players.replay_rate      AS replay_rate
  )
  DIMENSIONS (
    responses.brand AS brand
      WITH SYNONYMS ('lottery brand')
      COMMENT = 'NPL or VriendenLoterij',
    responses.email_type AS email_type
      COMMENT = 'Which email the survey was about'
      SAMPLE_VALUES ('welcome','prize_notification','monthly_update','winback')
      IS_ENUM,
    responses.survey_date AS survey_date
      COMMENT = 'Date the survey was answered',
    rounds.game_round_performance AS game_round_performance
      WITH SYNONYMS ('game outcome', 'round result')
      COMMENT = 'How the players game round went: good / normal / poor'
      SAMPLE_VALUES ('good','normal','poor')
      IS_ENUM
  )
  METRICS (
    responses.response_count   AS COUNT(responses.response_id)
      COMMENT = 'Number of survey responses',
    responses.avg_clarity      AS AVG(responses.clarity_rating)
      WITH SYNONYMS ('average clarity score')
      COMMENT = 'Average clarity rating (1-5)',
    responses.avg_tone         AS AVG(responses.tone_rating)
      COMMENT = 'Average tone rating (1-5)',
    responses.pct_low_clarity  AS AVG(IFF(responses.clarity_rating <= 2, 1, 0)) * 100
      COMMENT = 'Percent of responses rating clarity 2 or below'
  )
  COMMENT = 'Player email-survey clarity/tone analysis'
  AI_SQL_GENERATION 'A "poor game round" means game_round_performance = ''poor''. Low clarity means clarity_rating <= 2. Treat NPL and VriendenLoterij as the two brands. Round averages to 2 decimals.';

-- 1.3  Self-check: query the semantic view in SQL (Analyst uses the same object)
SELECT * FROM SEMANTIC_VIEW(
  SURVEY_ANALYSIS
  METRICS responses.avg_clarity, responses.response_count
  DIMENSIONS responses.brand
)
ORDER BY brand;

SELECT * FROM SEMANTIC_VIEW(
  SURVEY_ANALYSIS
  METRICS responses.avg_clarity, responses.pct_low_clarity
  DIMENSIONS rounds.game_round_performance
)
ORDER BY game_round_performance;


-- ============================================================================
-- STAGE 2 — CORE AI: precompute enrichment + live summaries  (02_core_ai...)
-- ============================================================================

-- 2.1  See the token cost BEFORE reduction (all comments, incl. junk)
SELECT
  COUNT(*)                                                        AS n_rows,
  SUM(SNOWFLAKE.CORTEX.COUNT_TOKENS('llama3.1-8b', clarity_comment)) AS total_tokens
FROM SURVEY_RESPONSES;

-- 2.2  AI_FILTER drops junk in plain language (replaces the "nee/nvt/-" tricks).
--      We filter over SURVEY_BASE so game_round_performance travels with the row.
CREATE OR REPLACE VIEW SURVEY_CLEAN AS
SELECT *
FROM SURVEY_BASE
WHERE clarity_comment IS NOT NULL
  AND AI_FILTER(PROMPT('Is this a substantive comment about an email, not an empty or throwaway answer: {0}', clarity_comment));

-- 2.3  Token cost AFTER reduction — compare with 2.1
SELECT
  COUNT(*)                                                        AS n_rows,
  SUM(SNOWFLAKE.CORTEX.COUNT_TOKENS('llama3.1-8b', clarity_comment)) AS total_tokens
FROM SURVEY_CLEAN;

-- 2.4  THE PIVOT: enrich each row ONCE, incrementally, as a Dynamic Table.
--      AI functions live in the SELECT, so an incremental refresh only reruns
--      them on NEW rows. The semantic view / agent then read plain columns.
CREATE OR REPLACE DYNAMIC TABLE SURVEY_ENRICHED
  TARGET_LAG = '1 hour'
  WAREHOUSE  = PLG_WORKSHOP_WH
AS
SELECT
  s.response_id,
  s.player_id,
  s.brand,
  s.email_type,
  s.survey_date,
  s.game_round_performance,
  s.clarity_rating,
  s.tone_rating,
  s.clarity_comment,
  s.tone_comment,
  AI_SENTIMENT(s.clarity_comment):categories[0]:sentiment::string        AS clarity_sentiment,
  AI_SENTIMENT(s.tone_comment):categories[0]:sentiment::string           AS tone_sentiment,
  AI_CLASSIFY(s.clarity_comment,
    ['content_clarity','layout','too_long','tone','technical','pricing','other']
  ):labels[0]::string                                                    AS clarity_topic
FROM SURVEY_CLEAN s;

-- 2.5  Verify enrichment on a sample
SELECT clarity_comment, clarity_sentiment, clarity_topic
FROM SURVEY_ENRICHED
LIMIT 10;

-- 2.6  Query-time synthesis done RIGHT: AI_AGG / AI_SUMMARIZE_AGG do the
--      map-reduce for you (no context-window limit, no batches of 50).
--      game_round_performance is a plain column on the enriched table now.
SELECT
  game_round_performance,
  AI_AGG(clarity_comment,
    'Summarise in English the top 3 recurring complaints about email clarity in these Dutch comments. Return a short bullet list.') AS top_clarity_issues
FROM SURVEY_ENRICHED
WHERE game_round_performance = 'poor'
GROUP BY game_round_performance;


-- ============================================================================
-- STAGE 3 — ADVANCED AI (STRETCH): Cortex Search  (03_advanced_ai_search...)
-- ============================================================================

-- 3.1  A managed, auto-embedded search service over the free text
CREATE OR REPLACE CORTEX SEARCH SERVICE SURVEY_FEEDBACK_SEARCH
  ON clarity_comment
  ATTRIBUTES brand, email_type, clarity_sentiment, clarity_topic
  WAREHOUSE = PLG_WORKSHOP_WH
  TARGET_LAG = '1 hour'
AS
  SELECT response_id, clarity_comment, brand, email_type, clarity_sentiment, clarity_topic
  FROM SURVEY_ENRICHED
  WHERE clarity_comment IS NOT NULL;

-- 3.2  "Find feedback like this", filtered — retrieval, not aggregation
SELECT PARSE_JSON(
  SNOWFLAKE.CORTEX.SEARCH_PREVIEW(
    'SURVEY_FEEDBACK_SEARCH',
    '{
       "query": "de e-mail was verwarrend en te lang",
       "columns": ["clarity_comment","brand","clarity_topic"],
       "filter": {"@eq": {"clarity_sentiment": "negative"}},
       "limit": 5
     }'
  )
) AS results;


-- ============================================================================
-- STAGE 4 — CONSUMPTION & EVALUATION  (04_consumption_eval...)
-- ============================================================================

-- 4.1  The structured half of the core question, via the semantic view
SELECT * FROM SEMANTIC_VIEW(
  SURVEY_ANALYSIS
  METRICS responses.avg_clarity, responses.pct_low_clarity, responses.response_count
  DIMENSIONS rounds.game_round_performance
)
ORDER BY game_round_performance;

-- 4.2  The "why" half — a live, grounded summary for the poor group
--      (uses game_round_performance carried on the enriched table; see notebook)
SELECT
  AI_AGG(clarity_comment,
    'These are Dutch survey comments from players whose game round went poorly. In English, explain the single biggest driver of negative clarity sentiment, with 2 supporting examples.') AS main_driver
FROM SURVEY_ENRICHED
WHERE clarity_sentiment = 'negative';

-- 4.3  Add ONE verified query by recreating the view with an AI_VERIFIED_QUERIES
--      block (a semantic view always needs its full definition).
CREATE OR REPLACE SEMANTIC VIEW SURVEY_ANALYSIS
  TABLES (
    responses AS SURVEY_RESPONSES PRIMARY KEY (response_id)
      WITH SYNONYMS ('survey','feedback','email survey'),
    rounds AS GAME_ROUNDS PRIMARY KEY (game_round_id),
    players AS PLAYER_BEHAVIOUR PRIMARY KEY (player_id)
  )
  RELATIONSHIPS (
    resp_to_round  AS responses (game_round_id) REFERENCES rounds (game_round_id),
    resp_to_player AS responses (player_id)     REFERENCES players (player_id)
  )
  FACTS (
    responses.clarity_rating AS clarity_rating,
    responses.tone_rating    AS tone_rating,
    players.replay_rate      AS replay_rate
  )
  DIMENSIONS (
    responses.brand AS brand COMMENT = 'NPL or VriendenLoterij',
    responses.email_type AS email_type SAMPLE_VALUES ('welcome','prize_notification','monthly_update','winback') IS_ENUM,
    responses.survey_date AS survey_date,
    rounds.game_round_performance AS game_round_performance SAMPLE_VALUES ('good','normal','poor') IS_ENUM
  )
  METRICS (
    responses.response_count  AS COUNT(responses.response_id),
    responses.avg_clarity     AS AVG(responses.clarity_rating),
    responses.avg_tone        AS AVG(responses.tone_rating),
    responses.pct_low_clarity AS AVG(IFF(responses.clarity_rating <= 2, 1, 0)) * 100
  )
  COMMENT = 'Player email-survey clarity/tone analysis (with verified query)'
  AI_SQL_GENERATION 'A poor game round means game_round_performance = ''poor''. Low clarity means clarity_rating <= 2.'
  AI_VERIFIED_QUERIES (
    clarity_by_round AS (
      QUESTION 'What is the average clarity by game round performance?'
      SQL 'SELECT game_round_performance, AVG(clarity_rating) AS avg_clarity
           FROM SURVEY_BASE GROUP BY game_round_performance ORDER BY game_round_performance'
    )
  );

-- 4.4  Evaluation: this is what "review functionality for semantic views" means.
--      Cortex Analyst evaluations score sql_correctness against verified queries
--      in Snowsight (AI & ML > Cortex Analyst > Evaluations). The notebook walks
--      through pointing an evaluation set at SURVEY_ANALYSIS.
