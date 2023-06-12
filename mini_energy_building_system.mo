model mini_energy_building_system
// Параметры здания
  parameter Real l = 200 "Длина здания";
  parameter Real h = 3.2 "Высота потолка";
  parameter Real w = 50 "Ширина здания";
  parameter Real V_build = l*w*h "Объём помещения м3";
  parameter Real n_lump = 500 "Количество лампочек";
  parameter Real S_wall = (l+w)*2*h "Площать стен";
  parameter Real S = l * w;
  //parameter Real a = 0.44/1000 "Теплопотери кирпичной стены [кВт/м*°C]";
  parameter Real R_wall = 1.4 "Сопротивление силикатного кирпича [м2*°C/Вт]";
  //Real Q_wall "Скорость теплопередачи стен";
  parameter Real Q_water_consumption_person = 30 "литры в минуту";
  parameter Real P_pump_pressure = 5 "Бар";
  parameter Real n_p_pump = 0.8 "КПД системы водоснабжения";
  // Константы вентиляции
  parameter Real V_flow = 10*200/1000*0.001*V_build;
  parameter Real pressure_vent = 500 "Па";
  parameter Real n_vent = 0.8;
  // Параметры освещения
  Real  E_lighting "кВт*ч";
  parameter Real W = 100*n_lump/1000 "кВт";
  parameter Real n_lump_efficiency = 0.9;
  // Параметры отопления 
  parameter Real Q_heating = 0;
  // Изменяемые параметры
  parameter Real n_people(start = 200);
  parameter Real n_condition = 20;
  parameter Real n_equipment = 100;
  // Параметры тепловыделения
  Real Q_equipment = n_equipment * 0.1;
  Real Q_people = n_people * 0.1;
  Real Q_lighting = n_lump * 0.8;
 
  // Ключевые переменные
  Real P_all_power;//
  Real P_condition = V_build/10;
  Real P_lightnig;//
  Real P_vent;//
  Real P_pump;//
  Real P_technique;//
  Real P_condition_all;//
  Real P_room_cooling;//
  Real P_room_heating;//
  Real P_heating;//
 
  
  //Параметры температуры
  parameter Real T_target = 18;
  parameter Real T_desired = 1.5;
 
  parameter Real T_min = 0 "Minimum ambient temperature";
  parameter Real T_max = 30 "Maximum ambient temperature";
  //Real T_room;
  Real T_amb(start=T_min) "Ambient temperature";
  Real T_rate "Rate of change of temperature";
  Real T_rate_room;
  Real T_room;
  Real time_day;
 
  
   // Определение ядра генератора
  parameter Integer initialSeed[2] = {123456789, 987654321};
  Integer currentSeed[2](start = initialSeed);
  Real temp_val(start = 0.5);
  
  // Параметры тепловыделения помещения
  Real Q_rate_people;
  Real Q_rate_equipment;
    
  Real n_rate_people;
  Real n_rate_equipment;
  Real n_rate_humidity;
  Real humidity(min = 0.1, max = 1) = 0.5;
    
    
equation
when sample(1*3600, 1*3600) then
 (temp_val, currentSeed) = Modelica.Math.Random.Generators.Xorshift64star.random(currentSeed);
 
  time_day = mod(time, 24*3600);
  T_rate = if time_day >= 6*3600 and time_day <=12*3600 then 1/1200*temp_val 
            elseif time_day >= 12*3600 and time_day <= 15*3600 then 1/1200*temp_val
            elseif time_day >= 15*3600 and time_day <= 18*3600 then 1/1200*temp_val
            elseif time_day >= 18*3600 and time_day <= 21*3600 then -1/1200*temp_val
            elseif time_day >= 21*3600 and time_day <= 27*3600 then -1/1200*temp_val
            else -1/1200*temp_val;
            
  if T_room > T_target then 
    P_room_cooling = abs(T_room-T_target)*n_condition*n_rate_humidity + n_rate_humidity*0.01;
    P_room_heating = 0;
  elseif T_room < T_target then 
    P_room_heating = abs(T_room-T_target)*n_condition*n_rate_humidity + n_rate_humidity*0.01;
    P_room_cooling = 0;
  else 
    P_room_cooling = 0;
    P_room_heating = 0;
  end if;

  n_rate_people = n_people*temp_val;
  n_rate_equipment = n_equipment*temp_val;
  n_rate_humidity = humidity*temp_val;
  
  Q_rate_people = n_people*temp_val*Q_people;
  Q_rate_equipment = n_equipment*temp_val*Q_equipment;
  
  P_heating = 1500*temp_val;
  P_technique = (0.5 * n_condition*temp_val);
  P_pump = Q_water_consumption_person*n_people*temp_val*P_pump_pressure / n_p_pump / 1000;
  P_vent = V_flow * pressure_vent*temp_val / n_vent / 1000;
  P_lightnig = W * temp_val * time_day * n_lump_efficiency/3600;
  E_lighting = W * temp_val * time_day/3600;
  P_condition_all = (P_room_cooling + P_room_heating);
  
  P_all_power = P_heating + P_pump + P_vent + P_lightnig + P_condition_all + P_technique;
  
end when;
  der(T_amb) = T_rate;
  T_rate_room = der(T_room);
  
  der(T_room) = (Q_rate_people + Q_rate_equipment + Q_lighting - P_room_cooling*1.16194 + P_room_heating*1.16194 - S_wall * R_wall * (T_room - T_amb)) / (S_wall * R_wall * 1.005* V_build * 0.0012);
 

end mini_energy_building_system;
