package com.neck.crack.feature.browser.presentation

import androidx.lifecycle.ViewModel
import com.neck.crack.feature.agent.domain.tool.browser.BrowserManager
import dagger.hilt.android.lifecycle.HiltViewModel
import javax.inject.Inject

@HiltViewModel
class BrowserViewModel @Inject constructor(
    val browserManager: BrowserManager
) : ViewModel()
