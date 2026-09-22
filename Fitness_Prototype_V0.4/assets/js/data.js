window.FitnessData = {
  nutrition: { calories:{value:1860,goal:2300}, protein:{value:142,goal:160}, carbs:{value:205,goal:260}, fat:{value:61,goal:70} },
  meals:[
    {time:'08:20',type:'早餐',title:'燕麦 + 牛奶 + 鸡蛋',kcal:510,p:31,c:58,f:17},
    {time:'12:35',type:'午餐',title:'米饭 250g + 鸡胸肉 180g',kcal:690,p:62,c:81,f:10},
    {time:'16:10',type:'加餐',title:'香蕉 + 希腊酸奶',kcal:260,p:17,c:39,f:5},
    {time:'20:05',type:'晚餐',title:'牛肉 + 土豆 + 蔬菜',kcal:400,p:32,c:27,f:29}
  ],
  foods:[
    {id:1,name:'熟鸡胸肉',brand:'公共食品库',source:'LOCAL',cal:165,p:31,c:0,f:3.6,unit:'100g'},
    {id:2,name:'白米饭（熟）',brand:'公共食品库',source:'LOCAL',cal:130,p:2.7,c:28.2,f:0.3,unit:'100g'},
    {id:3,name:'全脂牛奶',brand:'公共食品库',source:'LOCAL',cal:61,p:3.2,c:4.8,f:3.3,unit:'100ml'},
    {id:4,name:'2% 低脂牛奶',brand:'USDA FoodData Central',source:'API',cal:50,p:3.4,c:4.9,f:2.0,unit:'100ml'},
    {id:5,name:'脱脂牛奶',brand:'USDA FoodData Central',source:'API',cal:34,p:3.4,c:5.0,f:0.1,unit:'100ml'},
    {id:6,name:'鸡蛋（全蛋）',brand:'公共食品库',source:'LOCAL',cal:143,p:12.6,c:0.7,f:9.5,unit:'100g'},
    {id:7,name:'香蕉',brand:'公共食品库',source:'LOCAL',cal:89,p:1.1,c:22.8,f:0.3,unit:'100g'},
    {id:8,name:'即食燕麦片',brand:'公共食品库',source:'LOCAL',cal:379,p:13.2,c:67.7,f:6.5,unit:'100g'}
  ],
  plans:[
    {name:'PPL 9-Day Cycle',category:'力量',status:'进行中',cycle:['Push','Pull','Legs','Rest','Push','Pull','Legs','Rest','Rest'],today:'Push'},
    {name:'Easy Run',category:'有氧',status:'进行中',cycle:['—','Run','—','—','—','Run','—'],today:'—'},
    {name:'Shoulder Mobility',category:'恢复',status:'进行中',cycle:['Mobility','—','Mobility','—','Mobility','—','—'],today:'Mobility'}
  ],
  analytics:[
    {d:'09/16',cal:2140,p:154,c:246,f:67}, {d:'09/17',cal:2260,p:165,c:258,f:70},
    {d:'09/18',cal:1980,p:148,c:220,f:61}, {d:'09/19',cal:2380,p:171,c:275,f:72},
    {d:'09/20',cal:2210,p:159,c:251,f:68}, {d:'09/21',cal:2090,p:151,c:232,f:64},
    {d:'09/22',cal:1860,p:142,c:205,f:61}
  ]
};
