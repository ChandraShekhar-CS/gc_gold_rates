package com.example.flutter_application_1

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.json.JSONObject
import java.io.BufferedReader
import java.io.InputStreamReader
import java.net.HttpURLConnection
import java.net.URL

class RatesRepository {

    private val apiUrl = "https://goldrate.divyanshbansal.com/api/live"

    // Data class to hold the parsed rates
    data class RatesData(
        val gold995Sell: String,
        val silverFutureSell: String
        // Add other fields here if you need them later
    )

    // Sealed class for handling success and error states
    sealed class Result<out T : Any> {
        data class Success<out T : Any>(val data: T) : Result<T>()
        data class Error(val errorMessage: String) : Result<Nothing>()
    }

    // This is a suspend function, which means it can be paused and resumed.
    // It's the modern way to handle long-running operations in Kotlin.
    suspend fun fetchExtendedRates(): Result<RatesData> {
        // Use withContext to run the network call on the IO dispatcher
        return withContext(Dispatchers.IO) {
            try {
                val url = URL(apiUrl)
                val connection = url.openConnection() as HttpURLConnection
                connection.requestMethod = "GET"

                if (connection.responseCode == HttpURLConnection.HTTP_OK) {
                    val reader = BufferedReader(InputStreamReader(connection.inputStream))
                    val response = reader.readText()
                    reader.close()

                    val json = JSONObject(response)
                    val ratesData = RatesData(
                        gold995Sell = json.getJSONObject("gold").getString("sell"),
                        silverFutureSell = json.getJSONObject("silverfuture").getString("sell")
                    )
                    Result.Success(ratesData)
                } else {
                    Result.Error("Server error: ${connection.responseCode}")
                }
            } catch (e: Exception) {
                Result.Error(e.message ?: "An unknown error occurred")
            }
        }
    }
}
