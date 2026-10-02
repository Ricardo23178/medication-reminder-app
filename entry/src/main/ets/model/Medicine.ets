export class Medicine{
  id:number=0;
  userId:number=0;
  name:string='';
  specification:string='';
  dosage:string='';
  unit:string='';
  remark:string='';
  imageUrl:string='';
  enabled:number=0;
}

export class MedicineListResult{
  code: number = 0;
  message: string = '';
  data:Medicine[]=[]
}

export function  parseMedicineListResult(jsonStr: string):MedicineListResult{
  return JSON.parse(jsonStr) as MedicineListResult;
}

