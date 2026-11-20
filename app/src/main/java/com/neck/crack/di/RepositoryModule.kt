package com.neck.crack.di

import com.neck.crack.feature.settings.domain.repository.AIProviderRepository
import com.neck.crack.feature.settings.data.repository.AIProviderRepositoryImpl
import com.neck.crack.feature.credentials.domain.repository.CredentialRepository
import com.neck.crack.feature.credentials.data.repository.FileCredentialRepository
import dagger.Binds
import dagger.Module
import dagger.hilt.InstallIn
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
abstract class RepositoryModule {

    @Binds
    @Singleton
    abstract fun bindAIProviderRepository(
        aiProviderRepositoryImpl: AIProviderRepositoryImpl
    ): AIProviderRepository

    @Binds
    @Singleton
    abstract fun bindCredentialRepository(
        fileCredentialRepository: FileCredentialRepository
    ): CredentialRepository
}
