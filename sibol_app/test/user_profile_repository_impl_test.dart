import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sibol_app/features/auth/data/repositories/user_profile_repository_impl.dart';

void main() {
  test('updateTeenSelfProfile updates users doc only', () async {
    final firestore = FakeFirebaseFirestore();
    const uid = 'teen-uid-1';
    await firestore.collection('users').doc(uid).set({
      'role': 'teen',
      'displayName': 'Before',
      'active': true,
      'createdAt': Timestamp.now(),
      'assignedBarangay': 'Barangay 3',
      'dateOfBirth': '2010-01-01',
      'contactEmail': 'before@sibol.local',
    });
    await firestore.collection('cases').doc('case-1').set({
      'orgId': 'barangay03',
      'demoName': 'Case Teen',
      'fullName': 'Case Teen',
      'age': 16,
      'barangay': 'Barangay 3',
      'caseStatus': 'active',
      'subjectKind': 'registered',
      'teenUid': uid,
      'dateOfBirth': '2009-09-01',
      'contactEmail': 'case.only@sibol.local',
      'registeredAt': Timestamp.now(),
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
      'reportStatus': 'notSubmitted',
    });

    final repo = UserProfileRepositoryImpl(firestore);
    await repo.updateTeenSelfProfile(
      uid: uid,
      displayName: 'After Teen Name',
      assignedBarangay: 'Barangay 3, Balingasag',
      dateOfBirth: '2010-06-15',
      contactEmail: 'after@sibol.local',
      contactPhone: null,
      parentGuardianContact: null,
    );

    final user = await firestore.collection('users').doc(uid).get();
    expect(user.data()?['displayName'], 'After Teen Name');
    expect(user.data()?['dateOfBirth'], '2010-06-15');
    expect(user.data()?['contactEmail'], 'after@sibol.local');

    final caseDoc = await firestore.collection('cases').doc('case-1').get();
    expect(caseDoc.data()?['dateOfBirth'], '2009-09-01');
    expect(caseDoc.data()?['contactEmail'], 'case.only@sibol.local');
    expect(caseDoc.data()?['fullName'], 'Case Teen');
  });
}
