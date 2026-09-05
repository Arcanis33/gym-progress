const assert=require("node:assert/strict"),fs=require("node:fs"),vm=require("node:vm");
const source=fs.readFileSync("js/app.js","utf8");
const exercise={id:"one",name:"Test",muscle_group:"Ноги"};
const set={exercise_id:"one",workouts:{performed_at:"2026-09-01"}};
const state={exercises:[exercise],sets:[set],dayExercises:[{exercise_id:"one",day_type:"Ноги",position:0}],exerciseId:"one"};
let fail=false,confirmed=true;
const context={state,previewMode:false,confirm:()=>confirmed,Date,
  $:()=>({}),message:()=>{},closeDetail:()=>{},render:()=>{},renderExerciseLibrary:()=>{},showToast:()=>{},
  personSets:()=>state.sets,
  db:{from:()=>({update:()=>({eq:()=>({select:()=>({single:async()=>({error:fail?new Error("failed"):null})})})})})}};
vm.createContext(context);
for(const name of ["latestByExercise","planExercises"]){
  vm.runInContext(source.split(/\r?\n/).find(l=>l.startsWith("function "+name+"(")),context);
}
const start=source.indexOf("async function removeExercise("),end=source.indexOf("\nfunction ",start);
vm.runInContext(source.slice(start,end),context);
(async()=>{
  confirmed=false;await context.removeExercise("one",{});assert.equal(exercise.archived_at,undefined);
  confirmed=true;await context.removeExercise("one",{});
  assert.ok(exercise.archived_at);assert.equal(state.sets.length,1);assert.equal(state.dayExercises.length,1);
  assert.equal(context.latestByExercise().length,0);assert.equal(context.planExercises("Ноги").length,0);
  await context.removeExercise("one",{});
  assert.equal(exercise.archived_at,null);assert.equal(context.latestByExercise().length,1);
  assert.equal(context.planExercises("Ноги").length,1);assert.equal(state.sets[0],set);
  fail=true;const button={};await context.removeExercise("one",button);
  assert.equal(exercise.archived_at,null);assert.equal(button.disabled,false);
  console.log("PASS: cancel, archive, restore, history retention, failed request");
})().catch(error=>{console.error(error);process.exitCode=1});
