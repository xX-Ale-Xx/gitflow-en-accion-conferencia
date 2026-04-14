import { Module } from '@nestjs/common';
import { UsersService } from '../src/modules/users/services/users.service';

@Module({
  providers: [UsersService],
})
export class AppModule {}
