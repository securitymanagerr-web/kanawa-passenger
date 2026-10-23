// KANAWA - Pedir viagem
// v5.1 — Recolha automática + 1 input + Navegação para "A procurar motorista"

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

import 'searching_driver_screen.dart';

// ═══════════════════════════════════════════════════════════
// CORES KANAWA
// ═══════════════════════════════════════════════════════════
class _C {
  static const red = Color(0xFFE01818);
  static const redDark = Color(0xFFB91C1C);
  static const blue = Color(0xFF1E5FE0);
  static const blueDark = Color(0xFF0A4AD8);
  static const blueSoft = Color(0xFFE8F0FE);
  static const cyan = Color(0xFF00E5FF);
  static const green = Color(0xFF16A34A);
  static const greenSoft = Color(0xFFF0FDF4);
  static const amber = Color(0xFFD97706);
  static const purple = Color(0xFF7C3AED);
  static const teal = Color(0xFF0F766E);
  static const orange = Color(0xFFEA580C);
  static const indigo = Color(0xFF6366F1);
  static const textStrong = Color(0xFF18181B);
  static const textBase = Color(0xFF3F3F46);
  static const textMuted = Color(0xFF71717A);
  static const textSubtle = Color(0xFFA1A1AA);
  static const bgApp = Color(0xFFFAFAFA);
  static const bgSoft = Color(0xFFF4F4F5);
  static const border = Color(0xFFE4E4E7);
}

// ═══════════════════════════════════════════════════════════
// TIPOS DE POI
// ═══════════════════════════════════════════════════════════
enum _PoiType {
  market,
  hospital,
  airport,
  school,
  stadium,
  church,
  bank,
  restaurant,
  neighborhood,
  fuel,
  government,
  hotel,
  diamond,
  leisure,
}

class _Poi {
  final String name;
  final String area;
  final LatLng position;
  final _PoiType type;
  final bool hidden;
  final bool estimated;

  const _Poi({
    required this.name,
    required this.area,
    required this.position,
    required this.type,
    this.hidden = false,
    this.estimated = false,
  });
}

// ═══════════════════════════════════════════════════════════
// PONTOS REAIS DE SAURIMO
// ═══════════════════════════════════════════════════════════
const _knownPois = <_Poi>[
  // ─── 6 PONTOS VISÍVEIS ───
  _Poi(name: 'Mercado Central', area: 'Centro, Saurimo', position: LatLng(-9.6620, 20.3930), type: _PoiType.market),
  _Poi(name: 'Hospital Provincial (novo)', area: 'Saurimo', position: LatLng(-9.666173886192562, 20.358820794496566), type: _PoiType.hospital),
  _Poi(name: 'Governo Provincial da Lunda Sul', area: 'Saurimo', position: LatLng(-9.654201459161317, 20.39270433406372), type: _PoiType.government),
  _Poi(name: 'Aeroporto Deolinda Rodrigues', area: 'Saurimo', position: LatLng(-9.685605729890185, 20.423017453667974), type: _PoiType.airport),
  _Poi(name: 'Polo Diamantífero de Saurimo', area: 'Zona Norte, Saurimo', position: LatLng(-9.611527334440803, 20.414801285323275), type: _PoiType.diamond),
  _Poi(name: 'Polo Universitário Lueji A\'Nkonde', area: 'Bairro Luari, Saurimo', position: LatLng(-9.651281370297733, 20.482260632781585), type: _PoiType.school, estimated: true),

  // ─── SAÚDE ───
  _Poi(name: 'Hospital Municipal de Saurimo', area: 'Centro', position: LatLng(-9.658021275180799, 20.39437465293709), type: _PoiType.hospital, hidden: true),
  _Poi(name: 'Hospital Militar', area: 'Saurimo', position: LatLng(-9.653351931317367, 20.396793800276555), type: _PoiType.hospital, hidden: true),
  _Poi(name: 'Maternidade Provincial da Lunda Sul', area: 'Txizainga', position: LatLng(-9.666716858166222, 20.404135755213332), type: _PoiType.hospital, hidden: true),
  _Poi(name: 'Centro Materno Infantil de Saurimo', area: 'Saurimo', position: LatLng(-9.664615184702852, 20.40121311305153), type: _PoiType.hospital, hidden: true),
  _Poi(name: 'Centro de Saúde de Saurimo', area: 'Saurimo', position: LatLng(-9.659028116585493, 20.389875609986856), type: _PoiType.hospital, hidden: true),

  // ─── EDUCAÇÃO ───
  _Poi(name: 'Escola Politécnica do Luar', area: 'Luar, Saurimo', position: LatLng(-9.658688830255773, 20.474670172285308), type: _PoiType.school, hidden: true),
  _Poi(name: 'Instituto Médio Politécnico da Lunda Sul', area: 'Saurimo', position: LatLng(-9.657573078587161, 20.424320152492967), type: _PoiType.school, hidden: true),
  _Poi(name: 'Mediateca de Saurimo', area: 'Saurimo', position: LatLng(-9.658939386894428, 20.421716898528757), type: _PoiType.school, hidden: true),
  _Poi(name: 'Escola Portuguesa Lunda Sul', area: 'Saurimo', position: LatLng(-9.67031619098718, 20.35972982501365), type: _PoiType.school, hidden: true),
  _Poi(name: 'Complexo Escolar Nº 2 Padre Henrique Groesmith', area: 'Saurimo', position: LatLng(-9.650119942199348, 20.391155738470083), type: _PoiType.school, hidden: true),
  _Poi(name: 'Escola 28 de Maio', area: 'Bairro Candembe', position: LatLng(-9.66679431916214, 20.384261740788595), type: _PoiType.school, hidden: true),
  _Poi(name: 'Escola Primária Domingas Muta', area: 'Zona F, Candembe', position: LatLng(-9.67522660075173, 20.379518715635747), type: _PoiType.school, hidden: true),
  _Poi(name: 'Colégio Marcieth', area: 'Saurimo', position: LatLng(-9.659620706768889, 20.389670140161726), type: _PoiType.school, hidden: true),
  _Poi(name: 'Magistério Amor do Povo', area: 'Saurimo', position: LatLng(-9.661016652941841, 20.39063110784018), type: _PoiType.school, hidden: true),
  _Poi(name: 'Centro Formação ENDIAMA', area: 'Saurimo', position: LatLng(-9.660900347780913, 20.391897133051366), type: _PoiType.school, hidden: true),

  // ─── BANCOS ───
  _Poi(name: 'Banco BAI', area: 'Saurimo', position: LatLng(-9.657259746712725, 20.39075931343711), type: _PoiType.bank, hidden: true),
  _Poi(name: 'Banco BFA 11 de Novembro', area: 'Bairro 11 de Novembro', position: LatLng(-9.658177104032141, 20.395029347597127), type: _PoiType.bank, hidden: true),
  _Poi(name: 'BPC Verde', area: 'Saurimo', position: LatLng(-9.65936806779854, 20.39863763786818), type: _PoiType.bank, hidden: true),
  _Poi(name: 'Banco Millennium Atlântico', area: 'Saurimo', position: LatLng(-9.655892881079815, 20.394984159234465), type: _PoiType.bank, hidden: true),

  // ─── RESTAURANTES ───
  _Poi(name: 'Coffee Break', area: 'Saurimo', position: LatLng(-9.657456404555068, 20.398943039500804), type: _PoiType.restaurant, hidden: true),
  _Poi(name: 'Pizzaria Italiana', area: 'Saurimo', position: LatLng(-9.660043482160031, 20.39329179155725), type: _PoiType.restaurant, hidden: true),
  _Poi(name: 'Restaurante-Bar O Quintal', area: 'Bairro A. Neto', position: LatLng(-9.65356741771425, 20.39106133734538), type: _PoiType.restaurant, hidden: true),
  _Poi(name: 'Pastelaria Bonina', area: 'Saurimo', position: LatLng(-9.657758905310692, 20.391363470338966), type: _PoiType.restaurant, hidden: true),
  _Poi(name: 'Restaurante Mobil', area: 'Rua da Liberdade', position: LatLng(-9.657714887509284, 20.392482112535145), type: _PoiType.restaurant, hidden: true),
  _Poi(name: 'Espaço Kinteto - Esplanada Grill', area: 'Bairro Txizainga 1', position: LatLng(-9.656839387045405, 20.422793019181594), type: _PoiType.restaurant, hidden: true),
  _Poi(name: 'Bobo Internacional', area: 'Rua Txizainga', position: LatLng(-9.659168164462159, 20.41294023333159), type: _PoiType.restaurant, hidden: true),
  _Poi(name: 'Padaria Pão Lunda', area: 'Saurimo', position: LatLng(-9.658697081640167, 20.403873716705874), type: _PoiType.restaurant, hidden: true),

  // ─── HOTÉIS ───
  _Poi(name: 'Hotel Kawissa Saurimo', area: 'Bairro 11 Novembro', position: LatLng(-9.65666744560235, 20.392110116373697), type: _PoiType.hotel, hidden: true),
  _Poi(name: 'Hotel Seven Studios', area: 'Avenida da Liberdade', position: LatLng(-9.665487038255243, 20.387755241835258), type: _PoiType.hotel, hidden: true),
  _Poi(name: 'Hotel Princesinha', area: 'Saurimo', position: LatLng(-9.654900587062786, 20.38822213157022), type: _PoiType.hotel, hidden: true),
  _Poi(name: 'Solar Luboia Hotel', area: 'Saurimo', position: LatLng(-9.651875107510795, 20.39124569424679), type: _PoiType.hotel, hidden: true),
  _Poi(name: 'Hotel Riviera 62', area: 'Rua FAPLA Povo', position: LatLng(-9.6555933160055, 20.396636343118125), type: _PoiType.hotel, hidden: true),
  _Poi(name: 'Resort Uhenha', area: 'Bairro Agostinho Neto', position: LatLng(-9.647542747856885, 20.394561961499033), type: _PoiType.hotel, hidden: true),

  // ─── COMÉRCIO ───
  _Poi(name: 'Shoprite Saurimo', area: 'Bairro Txizainga 1', position: LatLng(-9.656878935807065, 20.412747156745596), type: _PoiType.market, hidden: true),
  _Poi(name: 'AngoMart Saurimo', area: 'Bairro Agostinho Neto', position: LatLng(-9.65881071982685, 20.387870196974102), type: _PoiType.market, hidden: true),
  _Poi(name: 'Fresmart Express Saurimo', area: 'Saurimo', position: LatLng(-9.65902811658548, 20.392717515345996), type: _PoiType.market, hidden: true),
  _Poi(name: 'Kero Saurimo', area: 'Centro', position: LatLng(-9.6585, 20.3925), type: _PoiType.market, hidden: true),
  _Poi(name: 'Mercado Comunal do Txizainga (Praça do Adolfo)', area: 'Bairro Txizainga', position: LatLng(-9.651613835666165, 20.42997878839071), type: _PoiType.market, hidden: true),
  _Poi(name: 'Novo Mercado do Quatorze', area: 'Saurimo', position: LatLng(-9.694170499244729, 20.401927368798194), type: _PoiType.market, hidden: true),
  _Poi(name: 'Mercado Portão do Leste (Candembe)', area: 'EN 230', position: LatLng(-9.663893049868982, 20.377272247323656), type: _PoiType.market, hidden: true),
  _Poi(name: 'Mercado Informal do Candembe', area: 'Saurimo', position: LatLng(-9.667615988175294, 20.373229553858856), type: _PoiType.market, hidden: true),

  // ─── COMBUSTÍVEL ───
  _Poi(name: 'Pumangol Centro', area: 'Saurimo', position: LatLng(-9.651086417740213, 20.395653471217653), type: _PoiType.fuel, hidden: true),
  _Poi(name: 'Pumangol Diamante', area: 'Saurimo', position: LatLng(-9.663723824421629, 20.36904262419689), type: _PoiType.fuel, hidden: true),

  // ─── SERVIÇOS PÚBLICOS ───
  _Poi(name: 'Administração Municipal de Saurimo', area: 'Rua FAPLA Povo', position: LatLng(-9.65555062934854, 20.39568900104759), type: _PoiType.government, hidden: true),
  _Poi(name: 'Administração Municipal de Muangueji', area: 'Saurimo', position: LatLng(-9.606241617407568, 20.417922377589175), type: _PoiType.government, hidden: true),
  _Poi(name: 'Administração do Cassengo', area: 'Cassengo', position: LatLng(-9.676965545242163, 20.409821955349724), type: _PoiType.government, hidden: true),
  _Poi(name: 'AGT', area: 'Largo dos CTT', position: LatLng(-9.65454826765457, 20.39381307224638), type: _PoiType.government, hidden: true),
  _Poi(name: 'Comissão Provincial Eleitoral', area: 'Av. Viana Rebelo', position: LatLng(-9.65472821827338, 20.391642279776235), type: _PoiType.government, hidden: true),
  _Poi(name: 'Ministério do Interior', area: 'Saurimo', position: LatLng(-9.65748384837003, 20.396246677719954), type: _PoiType.government, hidden: true),
  _Poi(name: 'Gabinete Provincial da Educação', area: 'Saurimo', position: LatLng(-9.655004310461399, 20.396406866739582), type: _PoiType.government, hidden: true),
  _Poi(name: 'Gabinete Provincial de Registos', area: 'Bairro Txizainga', position: LatLng(-9.671196303391692, 20.405282335904133), type: _PoiType.government, hidden: true),
  _Poi(name: 'Delegação Provincial de Finanças', area: 'Saurimo', position: LatLng(-9.654294422405261, 20.394676567767522), type: _PoiType.government, hidden: true),
  _Poi(name: 'Direcção Provincial de Viação e Trânsito', area: 'Saurimo', position: LatLng(-9.701925856895944, 20.41813236995282), type: _PoiType.government, hidden: true),
  _Poi(name: 'INEA', area: 'Bairro Verde', position: LatLng(-9.664593478036913, 20.393517964555482), type: _PoiType.government, hidden: true),
  _Poi(name: 'ENDE Saurimo', area: 'Bairro Agostinho Neto', position: LatLng(-9.655133256775493, 20.392868553963968), type: _PoiType.government, hidden: true),
  _Poi(name: 'Edifício Integrado dos Serviços da Justiça', area: 'Rua FAPLA Povo', position: LatLng(-9.654322811609733, 20.3946034748364), type: _PoiType.government, hidden: true),
  _Poi(name: 'Bombeiros Lunda Sul', area: 'Saurimo', position: LatLng(-9.653039184570277, 20.387512420576613), type: _PoiType.government, hidden: true),
  _Poi(name: 'Correios de Angola', area: 'Largo dos CTT', position: LatLng(-9.654336729960091, 20.394613045006945), type: _PoiType.government, hidden: true),
  _Poi(name: 'SIC', area: 'Saurimo', position: LatLng(-9.688657328438175, 20.417721612625165), type: _PoiType.government, hidden: true),

  // ─── DIAMANTÍFERO ───
  _Poi(name: 'Laboratório de Diamantes de Angola', area: 'Saurimo', position: LatLng(-9.700830522910982, 20.42467355445943), type: _PoiType.diamond, hidden: true),
  _Poi(name: 'Catoca Saurimo (Portaria)', area: 'Saurimo', position: LatLng(-9.436513795084107, 20.31953030022614), type: _PoiType.diamond, hidden: true),
  _Poi(name: 'Lavra do Ti Mola', area: 'Saurimo', position: LatLng(-9.320041313146323, 20.544448915137), type: _PoiType.diamond, hidden: true),
  _Poi(name: 'Luachimo', area: 'Saurimo', position: LatLng(-9.665746682643464, 20.584740203785763), type: _PoiType.diamond, hidden: true),

  // ─── LAZER ───
  _Poi(name: 'Pavilhão Eduardo Mingas', area: 'Txizainga 2', position: LatLng(-9.668349817405474, 20.415467359320303), type: _PoiType.leisure, hidden: true),
  _Poi(name: 'Cine Chicapa', area: 'Saurimo', position: LatLng(-9.65911273050033, 20.391834850514986), type: _PoiType.leisure, hidden: true),
  _Poi(name: 'Estádio da Lunda Sul', area: 'Saurimo', position: LatLng(-9.651943252935045, 20.393060592583357), type: _PoiType.stadium, hidden: true),
  _Poi(name: 'Centro Turístico do Luar', area: 'Luar, Saurimo', position: LatLng(-9.64950010432066, 20.491912899710414), type: _PoiType.leisure, hidden: true),
  _Poi(name: 'Jardim do Agostinho Neto', area: 'Bairro Agostinho Neto', position: LatLng(-9.653955961775234, 20.393861176211185), type: _PoiType.leisure, hidden: true),
  _Poi(name: 'Largo 1º de Maio', area: 'Saurimo', position: LatLng(-9.660805004330973, 20.393635114317817), type: _PoiType.leisure, hidden: true),
  _Poi(name: 'Parque Fotovoltaico de Saurimo', area: 'Saurimo', position: LatLng(-9.669283201742276, 20.458964476049843), type: _PoiType.leisure, hidden: true),

  // ─── IGREJAS ───
  _Poi(name: 'Igreja Bom Deus', area: 'Saurimo', position: LatLng(-9.659261133012158, 20.410008312239086), type: _PoiType.church, hidden: true),
  _Poi(name: 'Igreja Adventista do Sétimo Dia', area: 'Bairro Verde B', position: LatLng(-9.661703782731466, 20.397519465879018), type: _PoiType.church, hidden: true),
  _Poi(name: 'Igreja Evangélica Sambukila-A', area: 'Bairro Sambukila-A', position: LatLng(-9.673068904976114, 20.390504216376172), type: _PoiType.church, hidden: true),

  // ─── BAIRROS ───
  _Poi(name: 'Bairro Sassamba', area: 'Saurimo', position: LatLng(-9.659874254776954, 20.392311192585442), type: _PoiType.neighborhood, hidden: true),
  _Poi(name: 'Bairro 11 de Novembro', area: 'Saurimo', position: LatLng(-9.657286539576793, 20.394832331057064), type: _PoiType.neighborhood, hidden: true),
  _Poi(name: 'Bairro Agostinho Neto', area: 'Saurimo', position: LatLng(-9.65475, 20.38463), type: _PoiType.neighborhood, hidden: true),
  _Poi(name: 'Bairro Luavur', area: 'Saurimo', position: LatLng(-9.649569934085335, 20.380651250903878), type: _PoiType.neighborhood, hidden: true),
  _Poi(name: 'Bairro Verde', area: 'Saurimo', position: LatLng(-9.661710068643917, 20.398805153450702), type: _PoiType.neighborhood, hidden: true),
  _Poi(name: 'Bairro Txizainga 1', area: 'Saurimo', position: LatLng(-9.656823571670472, 20.408777536027024), type: _PoiType.neighborhood, hidden: true),
  _Poi(name: 'Bairro Txizainga 2', area: 'Saurimo', position: LatLng(-9.668349817405474, 20.415467359320303), type: _PoiType.neighborhood, hidden: true),
  _Poi(name: 'Bairro Juventude', area: 'Saurimo', position: LatLng(-9.662305383971868, 20.4422111935805), type: _PoiType.neighborhood, hidden: true),
  _Poi(name: 'Bairro Candembe', area: 'Saurimo', position: LatLng(-9.6614238, 20.3628172), type: _PoiType.neighborhood, hidden: true),
  _Poi(name: 'Bairro Sambukila-A', area: 'Saurimo', position: LatLng(-9.673068904976114, 20.390504216376172), type: _PoiType.neighborhood, hidden: true),
  _Poi(name: 'Bairro Cacanda', area: 'Zona Norte', position: LatLng(-9.6480, 20.3850), type: _PoiType.neighborhood, hidden: true),
  _Poi(name: 'Bairro Cidade Alta', area: 'Zona Sul', position: LatLng(-9.6720, 20.4010), type: _PoiType.neighborhood, hidden: true),
  _Poi(name: 'Bairro Mukonda', area: 'Zona Leste', position: LatLng(-9.6600, 20.4100), type: _PoiType.neighborhood, hidden: true),
  _Poi(name: 'Bairro Sagrada Esperança', area: 'Zona Oeste', position: LatLng(-9.6650, 20.3800), type: _PoiType.neighborhood, hidden: true),
  _Poi(name: 'Bairro Chifunga', area: 'Zona Norte', position: LatLng(-9.6520, 20.3950), type: _PoiType.neighborhood, hidden: true),
  _Poi(name: 'Bairro Mussende', area: 'Zona Oeste', position: LatLng(-9.6700, 20.3780), type: _PoiType.neighborhood, hidden: true),
  _Poi(name: 'Bairro Camalundo', area: 'Zona Leste', position: LatLng(-9.6550, 20.4150), type: _PoiType.neighborhood, hidden: true),
  _Poi(name: 'Mona Quimbundo', area: 'Comuna de Saurimo', position: LatLng(-9.923221948425434, 20.212513154436845), type: _PoiType.neighborhood, hidden: true),
  _Poi(name: 'Sombo', area: 'Comuna de Saurimo', position: LatLng(-9.6800, 20.4100), type: _PoiType.neighborhood, hidden: true),
  _Poi(name: 'Cassengo Sede', area: 'Município de Cassengo', position: LatLng(-9.676965545242163, 20.409821955349724), type: _PoiType.neighborhood, hidden: true),
  _Poi(name: 'Muangueji Sede', area: 'Município de Muangueji', position: LatLng(-9.606241617407568, 20.417922377589175), type: _PoiType.neighborhood, hidden: true),

  // ─── OUTROS ───
  _Poi(name: 'Empório do Saber', area: 'Bairro Juventude', position: LatLng(-9.662305383971868, 20.4422111935805), type: _PoiType.market, hidden: true),
  _Poi(name: 'TTA Pneus Comércio', area: 'Saurimo', position: LatLng(-9.658092786471224, 20.414823008125627), type: _PoiType.market, hidden: true),
  _Poi(name: 'Mwono Waha', area: 'Saurimo', position: LatLng(-9.556341070705729, 20.409737543667262), type: _PoiType.leisure, hidden: true),
  _Poi(name: 'Cemitério Municipal', area: 'Bairro Agostinho Neto', position: LatLng(-9.652834748590179, 20.388839761134392), type: _PoiType.leisure, hidden: true),
  _Poi(name: 'Cemitério do Catorze', area: 'Saurimo', position: LatLng(-9.683343743785722, 20.399967959323945), type: _PoiType.leisure, hidden: true),
];

IconData _iconForPoi(_PoiType type) {
  switch (type) {
    case _PoiType.market: return Icons.store_rounded;
    case _PoiType.hospital: return Icons.local_hospital_rounded;
    case _PoiType.airport: return Icons.flight_rounded;
    case _PoiType.school: return Icons.school_rounded;
    case _PoiType.stadium: return Icons.sports_soccer_rounded;
    case _PoiType.church: return Icons.church_rounded;
    case _PoiType.bank: return Icons.account_balance_rounded;
    case _PoiType.restaurant: return Icons.restaurant_rounded;
    case _PoiType.neighborhood: return Icons.location_city_rounded;
    case _PoiType.fuel: return Icons.local_gas_station_rounded;
    case _PoiType.government: return Icons.account_balance_rounded;
    case _PoiType.hotel: return Icons.hotel_rounded;
    case _PoiType.diamond: return Icons.diamond_rounded;
    case _PoiType.leisure: return Icons.park_rounded;
  }
}

Color _colorForPoi(_PoiType type) {
  switch (type) {
    case _PoiType.market: return _C.green;
    case _PoiType.hospital: return _C.red;
    case _PoiType.airport: return _C.cyan;
    case _PoiType.school: return _C.purple;
    case _PoiType.stadium: return _C.amber;
    case _PoiType.church: return _C.indigo;
    case _PoiType.bank: return _C.blue;
    case _PoiType.restaurant: return _C.orange;
    case _PoiType.neighborhood: return _C.textMuted;
    case _PoiType.fuel: return _C.amber;
    case _PoiType.government: return _C.teal;
    case _PoiType.hotel: return _C.cyan;
    case _PoiType.diamond: return const Color(0xFF06B6D4);
    case _PoiType.leisure: return _C.amber;
  }
}

class _NearbyDriver {
  final String id;
  final String name;
  final String vehicleType;
  final String plate;
  final double rating;
  LatLng position;
  double bearing;

  _NearbyDriver({
    required this.id,
    required this.name,
    required this.vehicleType,
    required this.plate,
    required this.rating,
    required this.position,
    this.bearing = 0,
  });
}

class _Category {
  final String id;
  final String label;
  final String description;
  final IconData icon;
  final int basePrice;
  final int pricePerKm;
  final int seats;
  final double speedKmh;

  const _Category({
    required this.id,
    required this.label,
    required this.description,
    required this.icon,
    required this.basePrice,
    required this.pricePerKm,
    required this.seats,
    required this.speedKmh,
  });

  int calcPrice(double km) => (basePrice + (pricePerKm * km)).round();
  int calcEta(double km) => (km / speedKmh * 60).ceil().clamp(2, 999);
}

const _categories = [
  _Category(id: 'MOTA', label: 'Mota', description: 'Rápido e económico', icon: Icons.two_wheeler_rounded, basePrice: 300, pricePerKm: 200, seats: 1, speedKmh: 35),
  _Category(id: 'ECONOMIC', label: 'Económico', description: 'O mais popular', icon: Icons.directions_car_rounded, basePrice: 600, pricePerKm: 190, seats: 4, speedKmh: 28),
  _Category(id: 'COMFORT', label: 'Conforto', description: 'Mais espaço', icon: Icons.directions_car_filled_rounded, basePrice: 800, pricePerKm: 190, seats: 4, speedKmh: 28),
  _Category(id: 'PREMIUM', label: 'Premium', description: 'Carros de luxo', icon: Icons.local_taxi_rounded, basePrice: 1500, pricePerKm: 190, seats: 4, speedKmh: 30),
];

class _PlaceResult {
  final String displayName;
  final String shortName;
  final LatLng position;
  final String? province;

  _PlaceResult({
    required this.displayName,
    required this.shortName,
    required this.position,
    this.province,
  });

  factory _PlaceResult.fromNominatim(Map<String, dynamic> json) {
    final address = json['address'] as Map<String, dynamic>? ?? {};
    final suburb = address['suburb'] ?? address['neighbourhood'] ?? address['quarter'] ?? '';
    final city = address['city'] ?? address['town'] ?? address['municipality'] ?? '';
    final state = address['state'] ?? '';
    final display = json['display_name'] as String? ?? '';

    String short;
    if (suburb.isNotEmpty && city.isNotEmpty) {
      short = '$suburb, $city';
    } else if (suburb.isNotEmpty) {
      short = suburb;
    } else if (city.isNotEmpty) {
      short = city;
    } else {
      final parts = display.split(',');
      short = parts.isNotEmpty ? parts.first.trim() : display;
    }

    return _PlaceResult(
      displayName: display,
      shortName: short,
      position: LatLng(
        double.tryParse(json['lat']?.toString() ?? '0') ?? 0,
        double.tryParse(json['lon']?.toString() ?? '0') ?? 0,
      ),
      province: state.isNotEmpty ? state : null,
    );
  }
}

class RideRequestScreen extends StatefulWidget {
  const RideRequestScreen({super.key});

  @override
  State<RideRequestScreen> createState() => _RideRequestScreenState();
}

class _RideRequestScreenState extends State<RideRequestScreen> {
  static const _defaultCenter = LatLng(-9.6608, 20.3917);

  final _destinationController = TextEditingController();
  GoogleMapController? _mapController;

  LatLng _userLocation = _defaultCenter;
  bool _isLoadingLocation = true;
  bool _locationDenied = false;
  String? _userProvince;

  LatLng? _destinationPosition;
  String? _destinationName;
  double? _distanceKm;

  String _selectedCategory = 'ECONOMIC';
  List<_PlaceResult> _searchResults = [];
  bool _isSearching = false;
  Timer? _debounce;
  String? _searchError;

  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  final List<_NearbyDriver> _drivers = [];
  Timer? _driversTimer;

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _driversTimer?.cancel();
    _destinationController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _getUserLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() {
            _isLoadingLocation = false;
            _locationDenied = true;
          });
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _isLoadingLocation = false;
            _locationDenied = true;
          });
        }
        return;
      }

      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.best,
            timeLimit: Duration(seconds: 10),
          ),
        );
      } catch (_) {
        position = await Geolocator.getLastKnownPosition();
      }

      if (!mounted || position == null) return;

      setState(() {
        _userLocation = LatLng(position!.latitude, position.longitude);
        _isLoadingLocation = false;
      });

      await _detectUserProvince();
      _generateMockDrivers();
      _startDriversAnimation();
      _rebuildMarkers();

      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_userLocation, 14),
      );
    } catch (e) {
      debugPrint('Erro GPS: $e');
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
          _locationDenied = true;
        });
      }
    }
  }

  Future<void> _detectUserProvince() async {
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse'
        '?lat=${_userLocation.latitude}'
        '&lon=${_userLocation.longitude}'
        '&format=json'
        '&zoom=10'
        '&addressdetails=1',
      );
      final response = await http.get(
        uri,
        headers: {'User-Agent': 'KanawaApp/1.0'},
      ).timeout(const Duration(seconds: 8));

      if (!mounted) return;
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final address = data['address'] as Map<String, dynamic>? ?? {};
        final state = address['state'] as String?;
        if (mounted && state != null) {
          setState(() => _userProvince = state);
        }
      }
    } catch (e) {
      debugPrint('Erro província: $e');
    }
  }

  void _generateMockDrivers() {
    final rand = math.Random(42);
    _drivers.clear();
    for (int i = 0; i < 4; i++) {
      final distanceKm = 0.3 + rand.nextDouble() * 1.2;
      final angle = rand.nextDouble() * 2 * math.pi;
      final dLat = (distanceKm / 111.0) * math.cos(angle);
      final dLng = (distanceKm / (111.0 * math.cos(_userLocation.latitude * math.pi / 180))) * math.sin(angle);
      final isMoto = i % 3 == 0;

      _drivers.add(_NearbyDriver(
        id: 'driver_$i',
        name: ['João M.', 'Carlos S.', 'Pedro K.', 'Ana L.'][i],
        vehicleType: isMoto ? 'moto' : 'car',
        plate: isMoto ? 'LD-0$i-MT' : 'LD-0$i-AA',
        rating: 4.5 + rand.nextDouble() * 0.5,
        position: LatLng(
          _userLocation.latitude + dLat,
          _userLocation.longitude + dLng,
        ),
        bearing: rand.nextDouble() * 360,
      ));
    }
  }

  void _startDriversAnimation() {
    _driversTimer?.cancel();
    _driversTimer = Timer.periodic(const Duration(milliseconds: 2500), (_) {
      if (!mounted) return;
      setState(() {
        for (final d in _drivers) {
          final dLat = (_userLocation.latitude - d.position.latitude) * 0.004;
          final dLng = (_userLocation.longitude - d.position.longitude) * 0.004;
          final newBearing = math.atan2(dLng, dLat) * 180 / math.pi;
          if ((newBearing - d.bearing).abs() > 20) {
            d.bearing = newBearing;
          }
          d.position = LatLng(
            d.position.latitude + dLat,
            d.position.longitude + dLng,
          );
        }
      });
      _rebuildMarkers();
    });
  }

  void _rebuildMarkers() {
    if (!mounted) return;
    final newMarkers = <Marker>{};

    newMarkers.add(Marker(
      markerId: const MarkerId('user'),
      position: _userLocation,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      infoWindow: const InfoWindow(title: 'A tua localização'),
      zIndex: 100,
    ));

    if (_destinationPosition != null) {
      newMarkers.add(Marker(
        markerId: const MarkerId('destination'),
        position: _destinationPosition!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(title: 'Destino: ${_destinationName ?? ""}'),
        zIndex: 90,
      ));
    }

    final visiblePois = _knownPois.where((poi) {
      if (poi.hidden) return false;
      if (_userProvince == null) return true;
      if (_userProvince!.toLowerCase().contains('lunda')) {
        return _calculateDistance(_userLocation, poi.position) < 40;
      }
      return _calculateDistance(_userLocation, poi.position) < 60;
    }).toList();

    for (int i = 0; i < visiblePois.length; i++) {
      final poi = visiblePois[i];
      newMarkers.add(Marker(
        markerId: MarkerId('poi_$i'),
        position: poi.position,
        icon: BitmapDescriptor.defaultMarkerWithHue(_hueForColor(_colorForPoi(poi.type))),
        infoWindow: InfoWindow(title: poi.name, snippet: poi.area),
        onTap: () => _setDestination(poi.position, poi.name),
        zIndex: 50,
      ));
    }

    for (final d in _drivers) {
      newMarkers.add(Marker(
        markerId: MarkerId(d.id),
        position: d.position,
        rotation: d.bearing,
        icon: BitmapDescriptor.defaultMarkerWithHue(
          d.vehicleType == 'moto' ? BitmapDescriptor.hueOrange : BitmapDescriptor.hueGreen,
        ),
        infoWindow: InfoWindow(
          title: d.name,
          snippet: '⭐ ${d.rating.toStringAsFixed(1)} • ${d.plate}',
        ),
        zIndex: 80,
      ));
    }

    setState(() => _markers = newMarkers);
  }

  double _hueForColor(Color color) {
    final hsl = HSLColor.fromColor(color);
    return hsl.hue;
  }

  void _setDestination(LatLng pos, String name) {
    final dist = _calculateDistance(_userLocation, pos);
    setState(() {
      _destinationPosition = pos;
      _destinationName = name;
      _destinationController.text = name;
      _distanceKm = dist;
      _searchResults = [];
      _isSearching = false;
    });
    _drawPolyline();
    _fitBounds();
    _rebuildMarkers();
    FocusScope.of(context).unfocus();
  }

  double _calculateDistance(LatLng a, LatLng b) {
    const R = 6371.0;
    final lat1 = a.latitude * math.pi / 180;
    final lat2 = b.latitude * math.pi / 180;
    final dLat = (b.latitude - a.latitude) * math.pi / 180;
    final dLon = (b.longitude - a.longitude) * math.pi / 180;
    final h = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) * math.cos(lat2) * math.sin(dLon / 2) * math.sin(dLon / 2);
    return R * 2 * math.asin(math.sqrt(h)) * 1.3;
  }

  void _drawPolyline() {
    if (_destinationPosition == null) return;
    setState(() {
      _polylines = {
        Polyline(
          polylineId: const PolylineId('route'),
          points: [_userLocation, _destinationPosition!],
          color: _C.blue,
          width: 5,
        ),
      };
    });
  }

  void _fitBounds() {
    if (_destinationPosition == null || _mapController == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bounds = LatLngBounds(
        southwest: LatLng(
          math.min(_userLocation.latitude, _destinationPosition!.latitude),
          math.min(_userLocation.longitude, _destinationPosition!.longitude),
        ),
        northeast: LatLng(
          math.max(_userLocation.latitude, _destinationPosition!.latitude),
          math.max(_userLocation.longitude, _destinationPosition!.longitude),
        ),
      );
      _mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80));
    });
  }

  void _clearDestination() {
    setState(() {
      _destinationController.clear();
      _destinationPosition = null;
      _destinationName = null;
      _distanceKm = null;
      _searchResults = [];
      _polylines = {};
    });
    _rebuildMarkers();
    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(_userLocation, 14));
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.trim().length < 3) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
        _searchError = null;
      });
      return;
    }

    final localResults = <_PlaceResult>[];
    for (final poi in _knownPois) {
      if (poi.name.toLowerCase().contains(query.toLowerCase()) ||
          poi.area.toLowerCase().contains(query.toLowerCase())) {
        localResults.add(_PlaceResult(
          displayName: '${poi.name}, ${poi.area}',
          shortName: poi.name,
          position: poi.position,
        ));
      }
    }

    if (localResults.isNotEmpty) {
      setState(() {
        _searchResults = localResults;
        _isSearching = false;
      });
    }

    _debounce = Timer(const Duration(milliseconds: 600), () {
      _searchPlaces(query.trim());
    });
  }

  Future<void> _searchPlaces(String query) async {
    if (!mounted) return;
    setState(() {
      _isSearching = true;
      _searchError = null;
    });

    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?q=${Uri.encodeComponent(query)}'
        '&format=json'
        '&limit=15'
        '&countrycodes=ao'
        '&addressdetails=1',
      );
      final response = await http.get(
        uri,
        headers: {'User-Agent': 'KanawaApp/1.0'},
      ).timeout(const Duration(seconds: 12));

      if (!mounted) return;
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes)) as List;
        final remoteResults = data
            .map((item) => _PlaceResult.fromNominatim(item as Map<String, dynamic>))
            .where((r) => r.position.latitude != 0 && r.position.longitude != 0)
            .toList();

        final combined = <_PlaceResult>[..._searchResults];
        for (final r in remoteResults) {
          final isDup = combined.any((c) =>
              (c.position.latitude - r.position.latitude).abs() < 0.0005 &&
              (c.position.longitude - r.position.longitude).abs() < 0.0005);
          if (!isDup) combined.add(r);
        }

        combined.sort((a, b) {
          final aIn = _userProvince != null && a.province == _userProvince;
          final bIn = _userProvince != null && b.province == _userProvince;
          if (aIn && !bIn) return -1;
          if (!aIn && bIn) return 1;
          final da = _calculateDistance(_userLocation, a.position);
          final db = _calculateDistance(_userLocation, b.position);
          return da.compareTo(db);
        });

        setState(() {
          _searchResults = combined.take(15).toList();
          _isSearching = false;
          if (combined.isEmpty) _searchError = 'Nenhum resultado encontrado';
        });
      } else {
        setState(() {
          _isSearching = false;
          if (_searchResults.isEmpty) _searchError = 'Erro ao pesquisar';
        });
      }
    } catch (e) {
      debugPrint('Erro Nominatim: $e');
      if (mounted) {
        setState(() {
          _isSearching = false;
          if (_searchResults.isEmpty) _searchError = 'Sem ligação à internet';
        });
      }
    }
  }

  // ═══════════════════════════════════════════════════════
  // CONFIRMAR — NAVEGA PARA "A PROCURAR MOTORISTA"
  // ═══════════════════════════════════════════════════════
  void _confirmRide() {
    if (_destinationPosition == null || _destinationName == null) return;

    final cat = _categories.firstWhere((c) => c.id == _selectedCategory);
    final price = cat.calcPrice(_distanceKm ?? 0);
    final eta = cat.calcEta(_distanceKm ?? 0);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SearchingDriverScreen(
          pickupLocation: _userLocation,
          destinationLocation: _destinationPosition!,
          destinationName: _destinationName!,
          categoryId: cat.id,
          categoryLabel: cat.label,
          priceKz: price,
          etaMin: eta,
          distanceKm: _distanceKm ?? 0,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bgApp,
      body: SafeArea(
        child: Column(
          children: [
            _buildMap(),
            _buildBottomSheet(),
          ],
        ),
      ),
    );
  }

  Widget _buildMap() {
    return SizedBox(
      height: 340,
      child: Stack(
        children: [
          Positioned.fill(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(target: _userLocation, zoom: 14),
              onMapCreated: (controller) {
                _mapController = controller;
                _rebuildMarkers();
              },
              markers: _markers,
              polylines: _polylines,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              compassEnabled: false,
              mapToolbarEnabled: false,
              onTap: (_) {},
              onLongPress: (latLng) {
                _setDestination(
                  latLng,
                  '${latLng.latitude.toStringAsFixed(4)}, ${latLng.longitude.toStringAsFixed(4)}',
                );
              },
            ),
          ),
          Positioned(
            left: 16,
            top: 16,
            child: _CircleIconButton(
              icon: Icons.arrow_back_rounded,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          Positioned(
            right: 16,
            top: 16,
            child: _CircleIconButton(
              icon: Icons.my_location_rounded,
              onPressed: () {
                _mapController?.animateCamera(
                  CameraUpdate.newLatLngZoom(_userLocation, 15),
                );
              },
            ),
          ),
          Positioned(
            left: 16,
            bottom: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isLoadingLocation)
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(color: _C.blue, strokeWidth: 2),
                    )
                  else
                    Icon(
                      _locationDenied ? Icons.location_off_rounded : Icons.gps_fixed_rounded,
                      size: 16,
                      color: _locationDenied ? _C.textMuted : _C.green,
                    ),
                  const SizedBox(width: 6),
                  Text(
                    _isLoadingLocation
                        ? 'A obter GPS...'
                        : _locationDenied
                            ? 'GPS desativado'
                            : '${_drivers.length} motoristas perto',
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: _C.textStrong,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSheet() {
    return Expanded(
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: _C.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildDestinationInput(),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: _buildContent(),
              ),
            ),
            if (_destinationPosition != null) _buildConfirmButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildDestinationInput() {
    final hasDest = _destinationPosition != null;
    return Container(
      decoration: BoxDecoration(
        color: _C.bgSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasDest ? _C.red : _C.border,
          width: hasDest ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Color(0xFFFEF2F2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.search_rounded, color: _C.red, size: 18),
            ),
          ),
          Expanded(
            child: TextField(
              controller: _destinationController,
              enabled: !hasDest,
              onChanged: _onSearchChanged,
              textInputAction: TextInputAction.search,
              style: GoogleFonts.inter(
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                color: _C.textStrong,
              ),
              decoration: InputDecoration(
                hintText: 'Para onde vais?',
                hintStyle: GoogleFonts.inter(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w500,
                  color: _C.textSubtle,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          if (hasDest)
            IconButton(
              icon: const Icon(Icons.close_rounded, color: _C.textMuted, size: 20),
              onPressed: _clearDestination,
            ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_destinationPosition != null) {
      return _buildCategoriesList();
    }
    if (_isSearching) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(color: _C.red, strokeWidth: 3),
            ),
            const SizedBox(height: 12),
            Text(
              'A procurar...',
              style: GoogleFonts.inter(fontSize: 13, color: _C.textMuted),
            ),
          ],
        ),
      );
    }
    if (_searchResults.isNotEmpty) return _buildSearchResults();
    if (_searchError != null) {
      return _buildMessage(
        icon: Icons.location_off_rounded,
        title: _searchError!,
        subtitle: 'Tenta outro nome',
      );
    }
    return _buildNearbySuggestions();
  }

  Widget _buildNearbySuggestions() {
    final candidates = _knownPois.where((p) {
      if (_userProvince == null) return !p.hidden;
      if (_userProvince!.toLowerCase().contains('lunda')) {
        return _calculateDistance(_userLocation, p.position) < 40;
      }
      return _calculateDistance(_userLocation, p.position) < 60;
    }).toList();

    candidates.sort((a, b) => _calculateDistance(_userLocation, a.position)
        .compareTo(_calculateDistance(_userLocation, b.position)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              _userProvince != null ? 'Perto de ti · $_userProvince' : 'Perto de ti',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: _C.textStrong,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _C.blueSoft,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${candidates.length}',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: _C.blue,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...candidates.take(15).map(
          (p) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _SuggestionTile(
              icon: _iconForPoi(p.type),
              color: _colorForPoi(p.type),
              title: p.name + (p.estimated ? ' ⚠️' : ''),
              subtitle: '${p.area} · ${_calculateDistance(_userLocation, p.position).toStringAsFixed(1)} km',
              onTap: () => _setDestination(p.position, p.name),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchResults() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${_searchResults.length} resultado(s)',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: _C.textMuted,
          ),
        ),
        const SizedBox(height: 12),
        ..._searchResults.map(
          (r) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _SuggestionTile(
              icon: Icons.location_on_outlined,
              color: _C.blue,
              title: r.shortName,
              subtitle: '${_calculateDistance(_userLocation, r.position).toStringAsFixed(1)} km · ${r.displayName}',
              onTap: () => _setDestination(r.position, r.shortName),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMessage({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(icon, size: 40, color: _C.textMuted),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _C.textStrong,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 12.5, color: _C.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesList() {
    final distance = _distanceKm ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [_C.blue, _C.blueDark]),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.route_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Distância estimada',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.85),
                      ),
                    ),
                    Text(
                      '${distance.toStringAsFixed(1)} km',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '≈ ${(distance / 28 * 60).ceil().clamp(2, 999)} min',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'em viagem',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: Colors.white.withOpacity(0.75),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Escolhe o teu transporte',
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: _C.textStrong,
          ),
        ),
        const SizedBox(height: 12),
        ..._categories.map((c) {
          final price = c.calcPrice(distance);
          final eta = c.calcEta(distance);
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _CategoryTile(
              category: c,
              price: price,
              eta: eta,
              selected: c.id == _selectedCategory,
              onTap: () => setState(() => _selectedCategory = c.id),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildConfirmButton() {
    final cat = _categories.firstWhere((c) => c.id == _selectedCategory);
    final price = cat.calcPrice(_distanceKm ?? 0);
    final eta = cat.calcEta(_distanceKm ?? 0);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: _confirmRide,
          style: ElevatedButton.styleFrom(
            backgroundColor: _C.red,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle_rounded, size: 20),
              const SizedBox(width: 8),
              Text(
                'CONFIRMAR · $price Kz · $eta min',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  const _CircleIconButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 14,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Icon(icon, color: _C.textStrong, size: 20),
      ),
    );
  }
}

class _SuggestionTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SuggestionTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _C.border),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _C.textStrong,
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: _C.textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: _C.textSubtle,
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final _Category category;
  final int price;
  final int eta;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryTile({
    required this.category,
    required this.price,
    required this.eta,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFF1F1) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? _C.red : _C.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: selected ? _C.red.withOpacity(0.1) : _C.bgSoft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                category.icon,
                color: selected ? _C.red : _C.textMuted,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.label,
                    style: GoogleFonts.inter(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: _C.textStrong,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${category.description} · $eta min',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _C.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$price Kz',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: selected ? _C.red : _C.textStrong,
                  ),
                ),
                Text(
                  '$eta min',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: _C.textMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}