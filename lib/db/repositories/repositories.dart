import 'package:sync_server/db/repositories/database_repository_abstract.dart';
import 'package:sync_server/db/repositories/postgres/authentication_repository_postgres.dart';
import 'package:sync_server/db/repositories/postgres/database_repository_postgres.dart';
import 'package:sync_server/db/repositories/sqlite/authentication_repository.dart';
import 'package:sync_server/db/repositories/sqlite/database_repository.dart';

import 'authentication_repository_abstract.dart';

// Change this line to compile for sqlite instead of postgres
const usePostgres = true;

AuthenticationRepositoryAbstract getAuthenticationRepository() {
  if (usePostgres) {
    return AuthenticationRepositoryPostgres();
  }
  return AuthenticationRepository();
}

DatabaseRepositoryAbstract getDatabaseRepository() {
  if (usePostgres) {
    return DatabaseRepositoryPostgres();
  }
  return DatabaseRepository();
}
