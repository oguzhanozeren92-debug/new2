import { useState } from 'react';
import { getOrCreateWeeklyPusulaReport } from '../services/pusulaPdfData.service';
import type { WeeklyPusulaReport } from '../types';

type Props={fieldId:string;fieldName:string};
const LABELS:Record<string,string>={parcel_geometry:'Parsel geometrisi',satellite_30d:'30 günlük uydu serisi',weather:'Hava geçmişi',activities:'Tarla işlemleri',soil_analysis:'Toprak analizi',resolved_diagnosis:'Tamamlanmış Pusula teşhisi',irrigation_kc:'Sulama / fenoloji kaydı'};
export function PusulaPdfPanel({fieldId,fieldName}:Props){
 const [report,setReport]=useState<WeeklyPusulaReport|null>(null),[loading,setLoading]=useState(false),[error,setError]=useState('');
 const run=async()=>{setLoading(true);setError('');try{setReport(await getOrCreateWeeklyPusulaReport(fieldId));}catch(e){setError(e instanceof Error?e.message:'PUSULAPDF hazırlanamadı.');}finally{setLoading(false);}};
 const s=report?.report_data;
 return <section style={{background:'#fff',border:'1px solid #e5e5e5',borderRadius:20,padding:18,color:'#111'}}>
  <div style={{fontSize:12,color:'#777',fontWeight:700}}>PUSULAPDF · PREMIUM</div><h2 style={{margin:'5px 0 3px'}}>{fieldName} Haftalık Raporu</h2>
  <p style={{margin:'0 0 14px',fontSize:13,color:'#666'}}>Gerçek tarla verileri haftalık snapshot olarak hazırlanır. Aynı hafta yeniden hesaplanmaz.</p>
  {!report&&<button onClick={run} disabled={loading} style={{width:'100%',padding:13,border:0,borderRadius:14,background:'#111',color:'#fff',fontWeight:800}}>{loading?'Pusula verileri topluyor…':'Haftalık Raporu Hazırla'}</button>}
  {error&&<p style={{fontSize:12,color:'#b42318'}}>{error}</p>}
  {s&&<><div style={{display:'grid',gridTemplateColumns:'repeat(2,minmax(0,1fr))',gap:8,marginTop:12}}>
   <Stat t="Alan" v={s.field.areaDecare==null?'Veri yok':`${s.field.areaDecare} da`}/><Stat t="Ürün" v={s.field.crop??'Veri yok'}/><Stat t="Uydu sahnesi" v={String(s.satellite.points.length)}/><Stat t="Tarla işlemi" v={String(s.activities.length)}/><Stat t="Toprak analizi" v={String(s.soilAnalyses.length)}/><Stat t="Teşhis" v={String(s.diagnoses.length)}/>
  </div><div style={{marginTop:14,padding:12,borderRadius:14,background:'#f6f6f6'}}><b>Rapor dönemi</b><div style={{fontSize:12,color:'#666',marginTop:3}}>{s.period.start} → {s.period.end}</div></div>
  {s.missing.length>0&&<div style={{marginTop:12}}><b style={{fontSize:13}}>Henüz bulunamayan veriler</b><div style={{display:'flex',flexWrap:'wrap',gap:6,marginTop:7}}>{s.missing.map(x=><span key={x} style={{fontSize:11,padding:'6px 8px',border:'1px solid #ddd',borderRadius:99}}>{LABELS[x]??x}</span>)}</div></div>}
  <button disabled style={{width:'100%',padding:13,border:0,borderRadius:14,background:'#e8e8e8',color:'#777',fontWeight:800,marginTop:14}}>PDF Renderer bağlanıyor</button></>}
 </section>;
}
function Stat({t,v}:{t:string;v:string}){return <div style={{padding:11,borderRadius:13,background:'#f6f6f6'}}><div style={{fontSize:10,color:'#777',fontWeight:700}}>{t}</div><div style={{fontSize:16,fontWeight:850,marginTop:2}}>{v}</div></div>}
