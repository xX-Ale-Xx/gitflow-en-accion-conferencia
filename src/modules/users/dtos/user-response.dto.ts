import { ApiProperty } from '@nestjs/swagger';

export class UserResponseDto {
  @ApiProperty({ example: 1, description: 'ID del usuario' })
  id: number;

  @ApiProperty({ example: 'john@example.com', description: 'Email del usuario' })
  email: string;

  @ApiProperty({ example: 'John Doe', description: 'Nombre del usuario' })
  name: string;

  @ApiProperty({ example: '2026-04-11T00:00:00Z', description: 'Fecha de creación' })
  createdAt: Date;

  @ApiProperty({ example: '2026-04-11T00:00:00Z', description: 'Fecha de actualización' })
  updatedAt: Date;
}
