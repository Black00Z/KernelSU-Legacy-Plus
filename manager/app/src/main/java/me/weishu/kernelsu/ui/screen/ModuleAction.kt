package me.weishu.kernelsu.ui.screen

import android.os.Environment
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Save
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.unit.dp
import com.ramcosta.composedestinations.annotation.Destination
import com.ramcosta.composedestinations.navigation.DestinationsNavigator
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import me.weishu.kernelsu.ui.util.LocalSnackbarHost
import me.weishu.kernelsu.ui.util.runModuleActionCompat
import java.io.File
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

@Composable
@Destination
fun ModuleActionScreen(
    navigator: DestinationsNavigator,
    moduleId: String,
    moduleName: String,
) {
    var text by rememberSaveable { mutableStateOf("") }
    var complete by rememberSaveable { mutableStateOf(false) }
    val log = rememberSaveable { StringBuilder() }
    val scrollState = rememberScrollState()
    val scope = rememberCoroutineScope()
    val snackBarHost = LocalSnackbarHost.current

    LaunchedEffect(Unit) {
        if (text.isNotEmpty() || complete) return@LaunchedEffect
        text = "Running action for $moduleName…\n\n"
        log.append(text)
        withContext(Dispatchers.IO) {
            val result = runCatching {
                runModuleActionCompat(
                    moduleId,
                    onStdout = {
                        text += "$it\n"
                        log.append(it).append('\n')
                    },
                    onStderr = {
                        text += "$it\n"
                        log.append(it).append('\n')
                    },
                )
            }
            result.onSuccess { shellResult ->
                val finalLine = "\n[exit ${shellResult.code}]\n"
                text += finalLine
                log.append(finalLine)
            }.onFailure {
                val finalLine = "\nError: ${it.message ?: it.javaClass.simpleName}\n"
                text += finalLine
                log.append(finalLine)
            }
            complete = true
        }
    }

    LaunchedEffect(text) {
        scrollState.animateScrollTo(scrollState.maxValue)
    }

    Scaffold(
        topBar = {
            ModuleActionTopBar(
                moduleName = moduleName,
                onBack = { navigator.popBackStack() },
                onSave = {
                    scope.launch {
                        val format = SimpleDateFormat("yyyy-MM-dd-HH-mm-ss", Locale.getDefault())
                        val file = File(
                            Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS),
                            "KernelSU_action_${moduleId}_${format.format(Date())}.log",
                        )
                        file.writeText(log.toString())
                        snackBarHost.showSnackbar("Log saved to ${file.absolutePath}")
                    }
                },
            )
        },
    ) { innerPadding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding)
                .verticalScroll(scrollState),
        ) {
            Text(
                modifier = Modifier.padding(12.dp),
                text = text,
                fontSize = MaterialTheme.typography.bodySmall.fontSize,
                fontFamily = FontFamily.Monospace,
            )
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun ModuleActionTopBar(
    moduleName: String,
    onBack: () -> Unit,
    onSave: () -> Unit,
) {
    TopAppBar(
        title = { Text("Action · $moduleName") },
        navigationIcon = {
            IconButton(onClick = onBack) {
                Icon(Icons.AutoMirrored.Filled.ArrowBack, "Back")
            }
        },
        actions = {
            IconButton(onClick = onSave) {
                Icon(Icons.Filled.Save, "Save log")
            }
        },
    )
}
