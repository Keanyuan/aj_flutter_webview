package com.plus.anji.ajflutterwebview;

import android.content.Context;
import android.util.AttributeSet;
import android.webkit.WebView;

/**
 * 作者 kean_qi on ${DATA}:26
 */
public class ObservableWebView  extends WebView {
    private OnScrollChangedCallback mOnScrollChangedCallback;

    public ObservableWebView(final Context context)
    {
        super(context);
    }

    public ObservableWebView(final Context context, final AttributeSet attrs)
    {
        super(context, attrs);
    }

    public ObservableWebView(final Context context, final AttributeSet attrs, final int defStyle)
    {
        super(context, attrs, defStyle);
    }


    @Override
    protected void onScrollChanged(int l, int t, int oldl, int oldt) {
        super.onScrollChanged(l, t, oldl, oldt);
        if(mOnScrollChangedCallback != null) mOnScrollChangedCallback.onScroll(l, t, oldl, oldt);
    }


    //get
    public OnScrollChangedCallback getmOnScrollChangedCallback() {
        return mOnScrollChangedCallback;
    }

    //set
    public void setmOnScrollChangedCallback(OnScrollChangedCallback mOnScrollChangedCallback) {
        this.mOnScrollChangedCallback = mOnScrollChangedCallback;
    }

    public static interface OnScrollChangedCallback
    {
        public void onScroll(int l, int t, int oldl, int oldt);
    }
}
