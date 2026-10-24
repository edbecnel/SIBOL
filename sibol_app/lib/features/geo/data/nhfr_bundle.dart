import 'dart:convert';

import 'package:flutter/services.dart';

class NhfrFacility {
  NhfrFacility({
    required this.nhfrFacilityCode,
    required this.facilityOfficialName,
    required this.facilityType,
    required this.psgcCityMunCode,
    required this.psgcRegionCode,
  });

  final String nhfrFacilityCode;
  final String facilityOfficialName;
  final String facilityType;
  final String psgcCityMunCode;
  final String psgcRegionCode;

  factory NhfrFacility.fromJson(Map<String, dynamic> json) {
    return NhfrFacility(
      nhfrFacilityCode: json['nhfrFacilityCode'] as String,
      facilityOfficialName: json['facilityOfficialName'] as String,
      facilityType: json['facilityType'] as String,
      psgcCityMunCode: json['psgcCityMunCode'] as String,
      psgcRegionCode: json['psgcRegionCode'] as String,
    );
  }
}

class NhfrBundle {
  NhfrBundle({required this.version, required this.facilities, this.synthetic = false});

  final String version;
  final List<NhfrFacility> facilities;
  final bool synthetic;

  static const defaultVersion = 'nhfr-synthetic-demo-v1';

  static Future<NhfrBundle> load({String version = defaultVersion}) async {
    final raw = await rootBundle.loadString('assets/geo/$version.json');
    final map = jsonDecode(raw) as Map<String, dynamic>;
    final list = (map['facilities'] as List<dynamic>)
        .map((e) => NhfrFacility.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    return NhfrBundle(
      version: map['version'] as String,
      facilities: list,
      synthetic: map['synthetic'] == true,
    );
  }
}
