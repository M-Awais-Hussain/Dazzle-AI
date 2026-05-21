import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/designer_earning.dart';
import 'package:ayyy/core/errors/exceptions.dart';

abstract class DesignerEarningsRepository {
  Future<List<DesignerEarning>> getEarnings(String designerId);
  Future<void> recordEarning(DesignerEarning earning);
}

class SupabaseDesignerEarningsRepository implements DesignerEarningsRepository {
  final SupabaseClient _supabase;

  SupabaseDesignerEarningsRepository(this._supabase);

  @override
  Future<List<DesignerEarning>> getEarnings(String designerId) async {
    try {
      final response = await _supabase
          .from('designer_earnings')
          .select()
          .eq('designer_id', designerId)
          .order('created_at', ascending: false);

      return (response as List<dynamic>)
          .map((e) => DesignerEarning.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> recordEarning(DesignerEarning earning) async {
    try {
      await _supabase.from('designer_earnings').insert({
        'designer_id': earning.designerId,
        'request_id': earning.requestId,
        'amount': earning.amount,
        'status': earning.status,
      });
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}

final designerEarningsRepositoryProvider = Provider<DesignerEarningsRepository>((ref) {
  return SupabaseDesignerEarningsRepository(Supabase.instance.client);
});
