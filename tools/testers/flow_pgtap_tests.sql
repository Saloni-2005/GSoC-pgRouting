CREATE OR REPLACE FUNCTION flow_no_crash(fn_name TEXT)
RETURNS SETOF TEXT AS
$BODY$
DECLARE
params TEXT[];
subs TEXT[];
BEGIN

  IF NOT min_version('3.2.0') AND fn_name IN ('pgr_maxFlowMinCost', 'pgr_maxFlowMinCost_Cost') THEN
    RETURN QUERY
    SELECT skip(1, 'Can not test before 3.2.0 on ' || fn_name);
    RETURN;
  END IF;

  IF fn_name = 'pgr_edgeDisjointPaths' THEN
    PREPARE edges AS
    SELECT id, source, target, cost, reverse_cost  FROM edges;
  ELSE
    PREPARE edges AS
    SELECT id,
    source,
    target,
    capacity,
    reverse_capacity,
    cost,
    reverse_cost
    FROM edges
    ORDER BY id;
  END IF;



  PREPARE null_ret AS
  SELECT id FROM vertices  WHERE id IN (-1);

  PREPARE null_ret_arr AS
  SELECT array_agg(id) FROM vertices  WHERE id IN (-1);


  RETURN QUERY
  SELECT isnt_empty('edges', 'Should be not empty to tests be meaningful');
  RETURN QUERY
  SELECT is_empty('null_ret', 'Should be empty to tests be meaningful');
  RETURN QUERY
  SELECT set_eq('null_ret_arr', 'SELECT NULL::BIGINT[]', 'Should be empty to tests be meaningful');

  -- one to one
  params = ARRAY['$$edges$$',
  '5::BIGINT',
  '6::BIGINT'
  ]::TEXT[];
  subs = ARRAY[
  'NULL',
  '(SELECT id FROM vertices  WHERE id IN (-1))',
  '(SELECT id FROM vertices  WHERE id IN (-1))'
  ]::TEXT[];

  RETURN query SELECT * FROM no_crash_test(fn_name,params, subs);

  subs = ARRAY[
  'NULL',
  'NULL::BIGINT',
  'NULL::BIGINT'
  ]::TEXT[];
  RETURN query SELECT * FROM no_crash_test(fn_name,params, subs);
  -- one to many

  params = ARRAY['$$edges$$',
  '1::BIGINT',
  'ARRAY[6,7]::BIGINT[]'
  ]::TEXT[];
  subs = ARRAY[
  'NULL',
  '(SELECT id FROM vertices  WHERE id IN (-1))',
  '(SELECT array_agg(id) FROM vertices  WHERE id IN (-1))'
  ]::TEXT[];

  RETURN query SELECT * FROM no_crash_test(fn_name,params, subs);

  subs = ARRAY[
  'NULL',
  'NULL::BIGINT',
  'NULL::BIGINT[]'
  ]::TEXT[];
  RETURN query SELECT * FROM no_crash_test(fn_name,params, subs);

  -- many to one
  params = ARRAY['$$edges$$',
  'ARRAY[6,7]::BIGINT[]',
  '5'
  ]::TEXT[];
  subs = ARRAY[
  'NULL',
  '(SELECT array_agg(id) FROM vertices  WHERE id IN (-1))',
  '(SELECT id FROM vertices  WHERE id IN (-1))'
  ]::TEXT[];

  RETURN query SELECT * FROM no_crash_test(fn_name,params, subs);

  subs = ARRAY[
  'NULL',
  'NULL::BIGINT[]',
  'NULL::BIGINT'
  ]::TEXT[];
  RETURN query SELECT * FROM no_crash_test(fn_name,params, subs);

  -- many to many
  params = ARRAY['$$edges$$',
  'ARRAY[5]::BIGINT[]',
  'ARRAY[6,7]::BIGINT[]'
  ]::TEXT[];
  subs = ARRAY[
  'NULL',
  '(SELECT array_agg(id) FROM vertices  WHERE id IN (-1))',
  '(SELECT array_agg(id) FROM vertices  WHERE id IN (-1))'
  ]::TEXT[];

  RETURN query SELECT * FROM no_crash_test(fn_name,params, subs);

  subs = ARRAY[
  'NULL',
  'NULL::BIGINT[]',
  'NULL::BIGINT[]'
  ]::TEXT[];
  RETURN query SELECT * FROM no_crash_test(fn_name,params, subs);

  IF NOT min_version('3.2.0') THEN
    RETURN QUERY
    SELECT skip(1, 'Combinations functionality is new on 3.2.0');
    RETURN;
  END IF;

  PREPARE combinations AS
  SELECT source, target  FROM combinations WHERE target NOT IN (5,6);
  PREPARE null_combinations AS
  SELECT source, target FROM combinations WHERE source IN (-1);
  RETURN QUERY
  SELECT isnt_empty('combinations', 'Should be not empty to tests be meaningful');
  RETURN QUERY
  SELECT is_empty('null_combinations', 'Should be empty to tests be meaningful');

  params = ARRAY['$$edges$$', '$$combinations$$']::TEXT[];
  subs = ARRAY[
  'NULL',
  '$$(SELECT source, target FROM combinations  WHERE source IN (-1))$$'
  ]::TEXT[];

  RETURN query SELECT * FROM no_crash_test(fn_name, params, subs);

  subs = ARRAY[
  'NULL',
  'NULL::TEXT'
  ]::TEXT[];
  RETURN query SELECT * FROM no_crash_test(fn_name, params, subs);

END
$BODY$
LANGUAGE plpgsql VOLATILE;


CREATE OR REPLACE FUNCTION flow_types_check(fn_name TEXT)
RETURNS SETOF TEXT AS
$BODY$
BEGIN
  RETURN QUERY SELECT has_function(fn_name);

  RETURN QUERY SELECT has_function(fn_name, ARRAY[ 'text', 'bigint', 'bigint' ]);
  RETURN QUERY SELECT has_function(fn_name, ARRAY[ 'text', 'anyarray', 'bigint' ]);
  RETURN QUERY SELECT has_function(fn_name, ARRAY[ 'text', 'bigint', 'anyarray' ]);
  RETURN QUERY SELECT has_function(fn_name, ARRAY[ 'text', 'anyarray', 'anyarray' ]);

  RETURN QUERY SELECT function_returns(fn_name, ARRAY[ 'text', 'bigint', 'bigint' ], 'setof record');
  RETURN QUERY SELECT function_returns(fn_name, ARRAY[ 'text', 'bigint', 'anyarray' ], 'setof record');
  RETURN QUERY SELECT function_returns(fn_name, ARRAY[ 'text', 'anyarray', 'bigint' ], 'setof record');
  RETURN QUERY SELECT function_returns(fn_name, ARRAY[ 'text', 'anyarray', 'anyarray' ], 'setof record');


  RETURN QUERY SELECT CASE
  WHEN min_version('3.2.0') THEN
    collect_tap(
      has_function(fn_name, ARRAY[ 'text', 'text']),
      function_returns(fn_name, ARRAY[ 'text', 'text'], 'setof record')
    )
  ELSE
    skip(2, 'Combinations signature added on version 3.2.0')
  END;

  RETURN QUERY SELECT CASE
  WHEN min_version('3.2.0') THEN
    collect_tap(

      function_args_eq(fn_name,
        $$VALUES
        ('{"","","","seq","edge","start_vid","end_vid","flow","residual_capacity"}'::TEXT[]),
        ('{"","","","seq","edge","start_vid","end_vid","flow","residual_capacity"}'::TEXT[]),
        ('{"","","","seq","edge","start_vid","end_vid","flow","residual_capacity"}'::TEXT[]),
        ('{"","","","seq","edge","start_vid","end_vid","flow","residual_capacity"}'::TEXT[]),
        ('{"","","seq","edge","start_vid","end_vid","flow","residual_capacity"}'::TEXT[])
        $$),

      function_types_eq(fn_name,
        $$VALUES
        ('{text,int8,int8,int4,int8,int8,int8,int8,int8}'::TEXT[]),
        ('{text,int8,anyarray,int4,int8,int8,int8,int8,int8}'::TEXT[]),
        ('{text,anyarray,int8,int4,int8,int8,int8,int8,int8}'::TEXT[]),
        ('{text,anyarray,anyarray,int4,int8,int8,int8,int8,int8}'::TEXT[]),
        ('{text,text,int4,int8,int8,int8,int8,int8}'::TEXT[])
        $$)
    )
  ELSE
    collect_tap(

      function_args_eq(fn_name,
        $$VALUES
        ('{"","","","seq","edge","start_vid","end_vid","flow","residual_capacity"}'::TEXT[]),
        ('{"","","","seq","edge","start_vid","end_vid","flow","residual_capacity"}'::TEXT[]),
        ('{"","","","seq","edge","start_vid","end_vid","flow","residual_capacity"}'::TEXT[]),
        ('{"","","","seq","edge","start_vid","end_vid","flow","residual_capacity"}'::TEXT[])
        $$),

      function_types_eq(fn_name,
        $$VALUES
        ('{text,int8,int8,int4,int8,int8,int8,int8,int8}'::TEXT[]),
        ('{text,int8,anyarray,int4,int8,int8,int8,int8,int8}'::TEXT[]),
        ('{text,anyarray,int8,int4,int8,int8,int8,int8,int8}'::TEXT[]),
        ('{text,anyarray,anyarray,int4,int8,int8,int8,int8,int8}'::TEXT[])
        $$)
    )
END;

END
$BODY$
LANGUAGE plpgsql VOLATILE;
