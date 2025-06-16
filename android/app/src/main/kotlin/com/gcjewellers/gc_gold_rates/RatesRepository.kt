package com.gcjewellers.rateswidget

import java.io.BufferedReader
import java.io.InputStreamReader
import java.net.HttpURLConnection
import java.net.URL
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.json.JSONObject

class RatesRepository {
    private val apiUrl = "https://goldrate.divyanshbansal.com/api/live"
    data class RatesData(val gold995Sell: String, val silverFutureSell: String)
    sealed class Result<out T : Any> {
        data class Success<out T : Any>(val data: T) : Result<T>()
        data class Error(val errorMessage: String) : Result<Nothing>()
    }
    suspend fun fetchExtendedRates(): Result<RatesData> {
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
                    val ratesData =
                            RatesData(
                                    gold995Sell = json.getJSONObject("gold").getString("sell"),
                                    silverFutureSell =
                                            json.getJSONObject("silverfuture").getString("sell")
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
