import { Module } from '@nestjs/common';
import { UsersService } from '../modules/users/services/users.service';

@Module({
  providers: [UsersService],
})
export class AppModule {}
