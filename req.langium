grammar Req

terminal HYPHEN: '-';
terminal ID: /[\^]?[_a-zA-Z][_a-zA-Z0-9]*/;
terminal INT returns number: /\d+/;
terminal STRING: /"([^"\\]|\\.)*"|'([^'\\]|\\.)*'/;
terminal STOPS: /[;,.]/;
hidden terminal ML_COMMENT: /\/\*[^]*?\*\//;
hidden terminal SL_COMMENT: /\/\/[^\n\r]*(\r?\n)?/;
hidden terminal WS: /[ \t\r\n]+/;
terminal ANY_OTHER: /./;

Actor:
    name=ID;

Stakeholder:
    name=ID;

Quantifier:
    name=ID;

Unit:
    name=ID;

Adverb:
    value=STRING;

ArticleInLowercase returns string:
    'a' | 'an' | 'the';

ArticleInUppercase returns string:
    'A' | 'An' | 'The';

ModalVerb returns string:
    'shall' | 'must' | 'should';

Not returns string:
    'not';

Beneficiary:
    (ArticleInLowercase? (participantActor+=[Actor]) 'and'?)+;

WhileStructure:
    keyword=('While' | 'while')
    preconditions=PreconditionStructure;

WhenStructure:
    keyword=('When' | 'when')
    trigger=(Trigger | FreeExpression);

IfStructure:
    keyword=('If' | 'if')
    preconditions=(Trigger | FreeExpression);

FreeExpression:
    free_format_text=STRING;

Trigger:
    modifier=Modifier?
    (actor=Beneficiary | (ArticleInLowercase? object=STRING))
    actions=ActionsExpression;

Modifier:
    name=('some' | 'any');

ActionsExpression:
    name=STRING;

PreconditionStructure:
    ItemizedConditions | NonItemizedConditions;

Time:
    ('at' 'a' ('minimum' | 'maximum') 'of')?
    ('every')?
    amount=(STRING|INT)
    units=[Unit];

ItemizedConditions:
    'the' 'following' 'conditions' 'are' 'satisfied' ':'
    (item+=HYPHEN) precondition+=Condition
    ((',' | ',' 'and' | ',' 'or' | 'and' | 'or')
    (item+=HYPHEN) precondition+=Condition)*;

NonItemizedConditions:
    expression=ConditionsOrExpression;

ConditionsOrExpression infers NonItemizedConditions:
    ConditionsAndExpression ({infer ConditionsOrExpression.left=current} ('or') right=ConditionsAndExpression)*;

ConditionsAndExpression infers NonItemizedConditions:
    ConditionsPrimaryExpression ({infer ConditionsAndExpression.left=current} ('and') right=ConditionsPrimaryExpression)*;

ConditionsPrimaryExpression infers NonItemizedConditions:
    '(' expression=ConditionsOrExpression ')' | condition=Condition;

// Placeholder for a rule that was not defined in the prompt
Condition:
    (beneficiary=Beneficiary? expression=STRING)
    | ('measured' scale=ID operator=('>=' | '<=' | '==' | '>' | '<') threshold=INT);

DURATION_EXPRESSION:
    'for' time=Time;

entry Model:
    // Define Quantifiers and Actors yourself
    (
        ('Quantifiers:' quantifiers+=Quantifier (',' quantifiers+=Quantifier)*) |
        ('Actors:' actors+=Actor (',' actors+=Actor)*) | // TODO: Living vs. Non-living actors
        ('Units:' units+=Unit (',' units+=Unit)*) |
        ('Stakeholders:' stakeholders+=Stakeholder (',' stakeholders+=Stakeholder)*)
    )*
    requirements+=Requirement*;

WITH_THE_AIM_EXPRESSION:
    'with' 'the' 'aim' 'of' ArticleInLowercase? goal=STRING;

BY_THE_MEANS_OF_EXPRESSION:
    'by' 'the' 'means' 'of' ArticleInLowercase? means=STRING;

Requirement:
    'req' requirementID=ID ':'
    earsPreStatement=EARSPreStatement
    requirementContent=RequirementContent
    relevantStakeholders=RelevantStakeholders
    measurement=MeasurementDefinition?;

// Optional, structured metadata for a measurement condition. Existing requirements remain valid.
MeasurementDefinition:
    'Measurement:' 'construct' construct=STRING
    'scale' scale=ID
    'range' minimum=INT '..' maximum=INT
    'operator' operator=('>=' | '<=' | '==' | '>' | '<')
    'threshold' threshold=INT
    ('method' method=STRING)?
    ('evidence' evidence=STRING)?
    '.';

RequirementContent:
    actor=[Actor] ModalVerb Not? requirementBlock=RequirementBlock duration?=DURATION_EXPRESSION? time?=Time? aim?=WITH_THE_AIM_EXPRESSION? means?=BY_THE_MEANS_OF_EXPRESSION? '.';


EARSPreStatement:
    (
        (WhileStructure | WhenStructure | IfStructure) ','? ArticleInLowercase | 
        ArticleInUppercase
    );

RelevantStakeholders:
    'Relevant-Stakeholders:' stakeholders+=[Stakeholder] (',' stakeholders+=[Stakeholder])*'.';

// Different types of requirement syntax based on verbs and structure
RequirementBlock:
    requirement_syntax=(ACT_114 | /* ACT_114_1 | */ ADMIT_64_3_1 | ADVISE_37_9 | ALLOW_64_1_1 | ASSESSMENT_34_1 | CHARACTERIZE_29_2_AND_29_2_1_1 | CLASSIFY_29_10 | COMPEL_59_1 | CONCEALMENT_16 | CONTRIBUTE_13_2_1 | CONTRIBUTE_13_2_1_1 | COOPERATE_73_1_1 | CREATE_26_4 | DEFEND_72_3 | DISCOVER_84 | DISTINGUISH_23_5_1 | ENABLE_CUSTOM | ENFORCE_63 | ENSURE_99 | ESTABLISH_55_5_1 | ESTIMATE_34_2_1 | EXCHANGE_13_6_1 | FORBID_64_4_1 | FUNCTION_105_2_1_1 | HELP_72_1_1_1 | IMAGE_IMPRESSION_25_1 | /* INVESTIGATE_35_4 | */ INVOLVE_107_1 | KEEP_15_2 | LEARN_14_1 | LIMIT_76 | OBTAIN_13_5_2 | OBTAIN_13_5_2_1 | OTHER_COS_45_4 | REFLEXIVE_APPEARANCE_48_1_2 | REGISTER_54_1_1_1 | REMEDY_45_7 | REMOVE_10_1 | REQUIRE_103_1 | RESPOND_113 | SAY_37_7_1_1 | SEE_30_1_1_1 | SEND_11_1_1 | STOP_55_4_1 | SUBJECT_CUSTOM | SUBSTITUTE_13_6_2_1 | SUSTAIN_55_6 | TRANSCRIBE_25_4 | TRANSFER_MESG_37_1_1 | TURN_26_6_1 | TURN_26_6_1_1 | USE_105_1);


PREPOSITION_LOC returns string:
    'to' | 'for' | 'of' | 'into' | 'in' | 'on' | 'at' | 'with' | 'near' | 'within' | 'inside' | 'outside' | 'through' | 'across' | 'around' | 'about' | 'over' | 'under' | 'beneath' | 'beyond' | 'atop' | 'upon' | 'along' | 'amid' | 'among' | 'between' | 'behind' | 'below' | 'beside' | 'despite' | 'during' | 'except' | 'inside of' | 'outside of' | 'past' | 'since' | 'toward' | 'towards' | 'underneath';

ACT_114:
    verb=('make' | 'engage in')
    eventuality=STRING;

// ACT_114_1: // Removed because of duplicate in FUNCTION_105_2_1_1
//     verb=('perform')
//     eventuality=STRING;

ADMIT_64_3_1:
    verb='permit'
    theme=STRING
    (
        (preposition=PREPOSITION_LOC ArticleInLowercase?)
    )?
    location=STRING;

ADVISE_37_9:
    verb=('notify' | 'alert' | 'inform') // Inform is originally in TELL-37.2, but we consider it as a synonym to 'notify'
    recipient=Beneficiary
    possibleRestriction=('against' | 'about' | 'of' | 'regarding' | 'concerning' | 'on' | 'respecting' | 'to')? // to is extra
    topic=STRING?
    ('of' beneficiary=Beneficiary)? // support informing of location of an actor.
;

ALLOW_64_1_1:
    verb=('allow')
    (
        (eventuality=STRING) |
        (beneficiary=Beneficiary eventuality=STRING)
    );

ASSESSMENT_34_1:
    verb=('review' | 'monitor' | 'track' | 'assess')
    theme=STRING
    (
            ('for' attribute=STRING) | 
            ('as' value=STRING) |
            ('of' beneficiary=Beneficiary)
    )?
    adverb?=Adverb?;

// INVESTIGATE_35_4:
//     verb='monitor'
//     location=STRING
//     ('for' theme=STRING)?
//     ?
//     ('with' 'the' 'aim' 'of' goal=STRING)?; // to support help 72 1 1 1

CHARACTERIZE_29_2_AND_29_2_1_1:
    verb=('identify' | 'interpret' | 'select')
    theme=STRING
    (
        'as' attribute=STRING |
        'to' 'be' attribute=STRING |
        'how' 'to'? attribute=STRING |
        'for' attribute=STRING |
        'using' ArticleInLowercase? means=STRING /* Custom from requirements text */ 
    )?;

CLASSIFY_29_10:
    verb='classify'
    theme=STRING
    (('as' | 'into' | 'in') goal=STRING)?;

COMPEL_59_1:
    VERB='motivate'
    patient=Beneficiary
    ('to' | 'into')?
    result=STRING;

CONCEALMENT_16:
    verb=('conceal' | 'redact' | 'hide')
    theme=STRING
    (
        ('from' ArticleInLowercase? recipient+=[Actor]) |
        ('related' 'to' ArticleInLowercase? (recipientActor+=[Actor] | recipientString+=STRING)) // STRING for "all users" etc.
        ('by' 'the' 'means' 'of' ArticleInLowercase? means+=STRING)
    )*;

CONTRIBUTE_13_2_1:
    verb=('deploy')
    theme=STRING
    (('to' | 'among') recipient=Beneficiary)?;

CONTRIBUTE_13_2_1_1:
    verb=('contribute' | 'provide')    
    theme=STRING 
    (('to' | 'among') recipient=Beneficiary)
    when?=UPON_REQUST?;

UPON_REQUST returns string:
    'upon' 'request';

COOPERATE_73_1_1:
    verb='collaborate'    
    (('with') beneficiary=Beneficiary)
    ('on' | 'in')
    theme=STRING
    ('of' attribute+=STRING)?
    ('regarding' attribute+=STRING)?;

CREATE_26_4:
    verb=('create' | 'produce' | 'calculate') // added produce, though we can decide which one of the verbs to use later.
    ArticleInLowercase?
    result=STRING
    (
        ('for' beneficiary=Beneficiary) |
        (('from' | 'out' 'of') material=STRING) |
        ('as' attribute=STRING)
    )?;

DEFEND_72_3:
    verb=('protect' | 'preserve') // added preserve
    (
        (
            beneficiary=(Beneficiary)
            (('against' | 'from') theme=STRING)?
        ) |
        (theme=STRING 'of' beneficiary=Beneficiary) // shall preserve the privacy of the user
    );

DISCOVER_84: // does this need to be more specific ('between X and Y')?
    verb=('discover' | 'determine')
    // including some rules from 84-1
    (
        ('from' source=STRING)? ('about')?
    )
    topic=STRING 
    ('between' option1=STRING 'and' option2=STRING)?;

DISTINGUISH_23_5_1:
    verb='distinguish'
    (
        ('between'? theme=STRING) |
        (theme=STRING) |
        (theme=STRING 'by' attribute=STRING) |
        (theme=STRING 'from' other=STRING ('by' attribute=STRING)?)
    );

ENABLE_CUSTOM:
    verb=('enable')
    theme=STRING
    ('between' ArticleInLowercase? beneficiary1=[Actor] 'and' ArticleInLowercase? beneficiary2=[Actor]);

ENFORCE_63:
    verb=('enforce' | 'control')
    theme=STRING
    (
        ('on' ArticleInLowercase? location=STRING) 
    )?;

ENSURE_99:
    verb=('ensure' | 'secure')
    beneficiary+=Beneficiary? 
    theme=STRING
    (('for' beneficiary+=Beneficiary) | ('of' beneficiary+=Beneficiary) | ('related' 'to' requirement=STRING))?; // related to another requirement 

ESTABLISH_55_5_1:
    verb=('open' | 'establish')
    patient=STRING
    (('with' | 'through') instrument=STRING);

ESTIMATE_34_2_1:
    verb=('estimate')
    attribute_or_value=STRING
    (beneficiary=Beneficiary STRING)?
    (
        ('of')? theme=STRING |
        ('in' | 'at') theme=STRING
    )?;

EXCHANGE_13_6_1:
    verb=('change' | 'exchange')
    theme=STRING
    (
        ('with' coAgent=Beneficiary) |
        ('for' coTheme+=STRING)
    );

FORBID_64_4_1:
    verb=('block' | 'prohibit')
    (
        (beneficiary=Beneficiary 'from' eventuality=STRING) |
        theme=STRING
    );

FUNCTION_105_2_1_1:
    verb=('perform' | 'operate')
    attribute=STRING;

HELP_72_1_1_1:
    verb=('assist')
    beneficiary=Beneficiary
    ('with' theme=STRING)?;

IMAGE_IMPRESSION_25_1:
    verb=('flag')
    (
        theme=STRING |
        (actors=Beneficiary 'as' theme=STRING) |
        (destination=STRING 'with' theme=STRING) |
        (theme=STRING PREPOSITION_LOC destination=STRING)
    );

INVOLVE_107_1:
    verb=('include' | 'involve' | 'enroll')
    theme=STRING
    ('in' goal=STRING)?;

KEEP_15_2:
    verb=('store' | 'keep' | 'retain')
    theme=STRING
    (
        (PREPOSITION_LOC ArticleInLowercase?) location=STRING
    )?;

LEARN_14_1: // including LEARN_14_2_1
    verb='learn'
    ('about' | 'of')?
    topic=STRING
    ('of' participant=Beneficiary)? // could this also be expressed using 'from'? This is not in the verbnet set.
    ('from' (source=STRING | beneficiary+=Beneficiary))?
    adverb?=Adverb?; // automatically

LIMIT_76:
    verb=('limit' | 'reduce' | 'restrict')
    theme=STRING
    ('to'? goal=STRING)?;

OBTAIN_13_5_2:
    verb=('collect' | 'download')
    theme=STRING
    ('from' (source=STRING | beneficiary+=Beneficiary) ('of' beneficiary+=Beneficiary)?)?
    ('at' ArticleInLowercase location=STRING ('of' beneficiary+=Beneficiary)?)?
    adverb?=Adverb?; // transparently, secretly, ...

OBTAIN_13_5_2_1:
    verb='obtain'
    theme=STRING
    ('from' (source=STRING | beneficiary+=Beneficiary) ('of' STRING)?)?
    ('for' asset=STRING)?;

OTHER_COS_45_4:
    verb='activate'
    patient=STRING
    ('with' instrument=STRING)?;

REFLEXIVE_APPEARANCE_48_1_2:
    verb='display'
    theme=STRING
    ('of' user=Beneficiary)?
    ('to' recipient=Beneficiary)?
    ('on' ArticleInLowercase? location=STRING)? // additional rule
;

REGISTER_54_1_1_1:
    verb='measure'
    (
        (theme=STRING) |
        (theme=STRING 'at' value=STRING)
    )
    ('of' beneficiary+=Beneficiary)?
;

REMEDY_45_7:
    verb=('configure' | 'disable')
    patient=STRING
    ('with' instrument=STRING)?
    ('of' beneficiary=Beneficiary);

REMOVE_10_1:
    verb=('delete' | 'remove')
    Modifier?
    theme=STRING
    ('from' ((ArticleInLowercase? location=STRING) | actor=Beneficiary))?
;

REQUIRE_103_1: // is this monitoring related within our context?
    verb='require'
    precondition=STRING
    ('from' source=STRING)?
    (('of' | 'for')? beneficiary=Beneficiary)?;

RESPOND_113:
    verb='respond'
    ('to' | 'against') ArticleInLowercase? theme=STRING
    ('with' eventuality=STRING)?
    ('within' time=Time)?;

SAY_37_7_1_1:
    verb=('propose')
    topic=STRING
    ('to' recipient=Beneficiary);

SEE_30_1_1_1:
    verb='detect'
    stimulus=STRING;

SEND_11_1_1:
    verb=('send' | 'transmit')
    theme=STRING
    (('from' ArticleInLowercase? (initial_location=STRING | fromActor+=[Actor]))? 'to' ArticleInLowercase? (destination=STRING | toActor+=[Actor]))
;

STOP_55_4_1:
    verb=('close' | 'terminate')
    eventuality=STRING;

SUBJECT_CUSTOM:
    verb=('subject')
    beneficiary=Beneficiary
    topic=STRING;

SUBSTITUTE_13_6_2_1:
    verb=('overwrite')
    location=STRING 'with' coTheme=STRING;

SUSTAIN_55_6:
    verb='maintain'
    theme=STRING
    ('through' ArticleInLowercase? instrument=STRING)? // I made this optional (it is not optional in verbnet)
    ('for' time=Time)?;

TRANSCRIBE_25_4:
    verb=('record' | 'document' | 'log')
    theme=STRING
    ((PREPOSITION_LOC | 'as') ((ArticleInLowercase? location=STRING) | beneficiary=Beneficiary))?
;

TRANSFER_MESG_37_1_1:
    verb=('summarize')
    (topic=STRING)?
    ('to' ArticleInLowercase? recipient=Beneficiary)?;

TURN_26_6_1:
    verb='alter'
    (
        (patient=STRING ('from' initial_state=STRING) ('into' result=STRING)) |
        (patient=STRING ('into' result=STRING))
    );

TURN_26_6_1_1:
    verb=('turn' | 'change' | 'convert')
    (
        (patient=STRING ('from' initial_state=STRING) (('to' | 'into') result=STRING)) |
        (patient=STRING (('to' | 'into') result=STRING))
    );

USE_105_1:
    verb=('use' | 'employ')
    theme=STRING
    (
        ('to' reason=STRING) // custom (not in verbnet)
    )?;

// TODO: Add support for 'and'/'or' in itemized conditions (The System should monitor "vital signs remotely". and detect abnormal events / risky situations and sending information to formal and informal caregivers)