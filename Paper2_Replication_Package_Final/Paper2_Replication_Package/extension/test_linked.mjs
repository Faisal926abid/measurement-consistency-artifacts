import {EmptyFileSystem} from 'langium';
import {createReqServices} from './packages/language/out/req-module.js';
const {Req}=createReqServices({...EmptyFileSystem});
const head='Stakeholders: Driver\nActors: Driver, System\n\n';
const tail='\n    the System shall alert the Driver.\n    Relevant-Stakeholders: Driver.\n';
const meta=(scale='KSS',op='>=',threshold=8)=>`    Measurement: construct "driver drowsiness" scale ${scale} range 1..9 operator ${op} threshold ${threshold} method "KSS self-report" evidence "test observations".\n`;
const cases=[
['original',head+`req DDAW01: While "the driver's drowsiness level is equivalent to or above level 8 on the Karolinska Sleepiness Scale",`+tail],
['linked_valid',head+'req DDAW01: While measured KSS >= 8,'+tail+meta()],
['linked_threshold_mismatch',head+'req DDAW01: While measured KSS >= 8,'+tail+meta('KSS','>=',7)],
['linked_operator_mismatch',head+'req DDAW01: While measured KSS >= 8,'+tail+meta('KSS','>',8)],
['linked_scale_mismatch',head+'req DDAW01: While measured KSS >= 8,'+tail+meta('OTHER','>=',8)],
['linked_missing_metadata',head+'req DDAW01: While measured KSS >= 8,'+tail]
];
for(const [name,source] of cases){
 const result=Req.parser.LangiumParser.parse(source);
 const req=result.value.requirements?.[0];const diagnostics=[];
 if(req){Req.validation.ReqValidator.checkRequirement(req,(severity,message)=>diagnostics.push({severity,message}));if(req.measurement)Req.validation.ReqValidator.checkMeasurementDefinition(req.measurement,(severity,message)=>diagnostics.push({severity,message}));}
 console.log(JSON.stringify({name,parserErrors:result.parserErrors.map(x=>x.message),diagnostics}));
}
